require 'rspec'
require 'securerandom'
require 'rest-client'
require 'support/environment'
require 'support/cf'
require 'support/manifest'

RSpec.configure {
  include EnvironmentHelpers
  include ManifestHelpers
}

describe 'accessing the bits-service', type: :integration do
  let(:zip_file) { File.new(File.expand_path('../assets/empty.zip', __FILE__)) }
  let(:guid) do
    if !cc_updates_enabled?
      SecureRandom.uuid
    else
      @cf_client.create_package(@app_id)
    end
  end
  before :all do
    if cc_updates_enabled?
      @cf_client = CFClient::Client.new(cc_api_url, cc_user, cc_password)
      @org_id = @cf_client.create_org
      expect(@org_id).to_not be_empty
      @space_id = @cf_client.create_space(@org_id)
      expect(@space_id).to_not be_empty
      @app_id = @cf_client.create_app(@space_id)
      expect(@app_id).to_not be_empty
    end
  end
  after :all do
    if cc_updates_enabled?
      @cf_client.delete_org(@org_id)
      expect(@cf_client.get_org(@org_id)['error_code']).to eq('CF-OrganizationNotFound')
    end
  end

  before do
    RestClient::Resource.new(
      "https://#{private_endpoint_ip}/packages/#{guid}",
      verify_ssl: OpenSSL::SSL::VERIFY_PEER,
      ssl_ca_file: ca_cert).put({ package: zip_file },
      { host: private_endpoint.hostname }
      )
  end

  after do
    RestClient::Resource.new(
      "https://#{private_endpoint_ip}/packages/#{guid}",
      verify_ssl: OpenSSL::SSL::VERIFY_PEER,
      ssl_ca_file: ca_cert).delete({ host: private_endpoint.hostname }
      )
  end

  context 'by IP address' do
    context 'not passing a host header' do
      it 'responds with 400, because URL is used as host the host is unknown and therefore it is a bad request' do
        puts "https://#{private_endpoint_ip}/packages/#{guid}"
        expect { RestClient::Request.execute({
          url: "https://#{private_endpoint_ip}/packages/#{guid}",
          method: :get,
          verify_ssl: OpenSSL::SSL::VERIFY_PEER,
          ssl_ca_file: ca_cert
          })
        }.to raise_error(RestClient::BadRequest)
      end
    end

    context 'passing header "host: <public_endpoint>"' do
      it 'responds with 404, because host is public and the public host does not allow unsigned access to packages' do
        expect { RestClient::Request.execute({
          url: "https://#{private_endpoint_ip}/packages/#{guid}",
          method: :get, verify_ssl: OpenSSL::SSL::VERIFY_PEER,
          ssl_ca_file: ca_cert,
          headers: { host: public_endpoint.hostname }
          })
        }.to raise_error(RestClient::ResourceNotFound)
      end
    end
  end

  context 'by private endpoint' do
    context 'passing header "host: <public_endpoint>"' do
      it 'responds with 404, because host is public and the public host does not allow unsigned access to packages' do
        expect { RestClient::Request.execute({
          url: "#{private_endpoint}/packages/#{guid}",
          method: :get,
          verify_ssl: OpenSSL::SSL::VERIFY_PEER,
          ssl_ca_file: ca_cert, headers: { host: public_endpoint.hostname }
          })
        }.to raise_error(RestClient::ResourceNotFound)
        # expect { RestClient.get("#{private_endpoint}/packages/#{guid}", { host: public_endpoint.hostname }) }.to raise_error(RestClient::ResourceNotFound)
      end
    end

    context 'not passing any header' do
      it 'responds with 200, because host is private and the private host allows unsigned access to packages' do
        response = RestClient.get("#{private_endpoint}/packages/#{guid}")
        expect(response.code).to eq(200)
      end
    end

    context 'passing header "host: <private_endpoint>"' do
      it 'responds with 200, because host is private and the private host allows unsigned access to packages' do
        # This test is intentionally empty, because https://github.com/rest-client/rest-client follows
        # redirects keeping the original host header in the new request, which obviously breaks when using the blobstore.
        # It seems like this is a bug in rest-client, but it is unclear and remains as a TODO.
      end
    end
  end

  context 'by public endpoint' do
    context 'not passing a host header' do
      it 'responds with 404, because URL is used as Host header and the public host does not allow unsigned access to packages' do
        expect { RestClient.get("#{public_endpoint}/packages/#{guid}", {}) }.to raise_error(RestClient::ResourceNotFound)
      end
    end

    context 'passing header "host: <public_endpoint>"' do
      it 'responds with 404, because host is public and the public host does not allow unsigned access to packages' do
        expect { RestClient.get("#{public_endpoint}/packages/#{guid}", { host: public_endpoint.hostname }) }.to raise_error(RestClient::ResourceNotFound)
      end
    end
  end
end
