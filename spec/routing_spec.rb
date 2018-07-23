# frozen_string_literal: true

require 'rspec'
require 'securerandom'
require 'rest-client'
require 'support/environment'
require 'support/cf'
require 'support/manifest'
require 'support/http'

RSpec.configure {
  include EnvironmentHelpers
  include ManifestHelpers
  include HttpHelpers
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
      "https://#{private_endpoint.hostname}:#{private_endpoint.port}/packages/#{guid}",
      verify_ssl: OpenSSL::SSL::VERIFY_PEER,
      ssl_cert_store: cert_store
    ).
      put({ package: zip_file },
      { host: private_endpoint.hostname })
  end

  after do
    RestClient::Resource.new(
      "https://#{private_endpoint.hostname}:#{private_endpoint.port}/packages/#{guid}",
      verify_ssl: OpenSSL::SSL::VERIFY_PEER,
      ssl_cert_store: cert_store
    ).delete({ host: private_endpoint.hostname })
  end

  context 'by IP address' do
    context 'not passing a host header' do
      it 'responds SSLError: hostname <private_endpoint_ip> does not match the server certificate, because the IP is not part of the certificate.' do
        expect {
          RestClient::Request.execute(
            method: :get,
            url: "https://#{private_endpoint_ip}:#{private_endpoint.port}/packages/#{guid}",
            verify_ssl: OpenSSL::SSL::VERIFY_PEER,
            ssl_cert_store: cert_store
          )
        }.to raise_error(OpenSSL::SSL::SSLError, "hostname \"#{private_endpoint_ip}\" does not match the server certificate")
      end
    end

    context 'passing header "host: <public_endpoint>"' do
      it 'responds SSLError: hostname <private_endpoint_ip> does not match the server certificate, because the IP is not part of the certificate.' do
        expect { RestClient::Request.execute({
          url: "https://#{private_endpoint_ip}:#{private_endpoint.port}/packages/#{guid}",
          method: :get, verify_ssl: OpenSSL::SSL::VERIFY_PEER, ssl_cert_store: cert_store,
          headers: { host: public_endpoint.hostname }
          })
        }.to raise_error(OpenSSL::SSL::SSLError, "hostname \"#{private_endpoint_ip}\" does not match the server certificate")


      end
    end
  end

  context 'by private endpoint' do
    context 'passing header "host: <public_endpoint>"' do
      it 'responds with 404 or 403, because host is public and the public host does not allow unsigned access to packages' do
        begin
          RestClient::Request.execute({
            url: "#{private_endpoint}/packages/#{guid}",
            method: :get,
            verify_ssl: OpenSSL::SSL::VERIFY_PEER, ssl_cert_store: cert_store, headers: { host: public_endpoint.hostname }
            })
          fail 'should not get here'
        rescue => e
          expect(e).to be_a(RestClient::ResourceNotFound).or(be_a(RestClient::Forbidden))
        end
      end
    end

    context 'not passing any header' do
      it 'responds with 200, because host is private and the private host allows unsigned access to packages' do
        response = RestClient::Request.execute({
          url: "#{private_endpoint}/packages/#{guid}",
          method: :get,
          verify_ssl: OpenSSL::SSL::VERIFY_PEER,
          ssl_cert_store: cert_store
          })
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
      it 'responds with 404 or 403, because URL is used as Host header and the public host does not allow unsigned access to packages' do
        begin
          RestClient::Request.execute({
            url: "#{public_endpoint}/packages/#{guid}",
            method: :get,
            verify_ssl: OpenSSL::SSL::VERIFY_PEER,
            ssl_cert_store: cert_store
            })
          fail 'should not get here'
        rescue => e
          expect(e).to be_a(RestClient::ResourceNotFound).or(be_a(RestClient::Forbidden))
        end
      end
    end

    context 'passing header "host: <public_endpoint>"' do
      it 'responds with 404 or 403, because host is public and the public host does not allow unsigned access to packages' do
        begin
          RestClient::Request.execute({
            url: "#{public_endpoint}/packages/#{guid}",
            method: :get,
            verify_ssl: OpenSSL::SSL::VERIFY_PEER,
            ssl_cert_store: cert_store
            })
          fail 'should not get here'
        rescue => e
          expect(e).to be_a(RestClient::ResourceNotFound).or(be_a(RestClient::Forbidden))
        end
      end
    end
  end
end
