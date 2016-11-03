require 'rspec'
require 'rest-client'
require 'support/environment'
require 'support/manifest'

RSpec.configure {
  include EnvironmentHelpers
  include ManifestHelpers
}

describe 'accessing the bits-service', type: :integration do
  let(:zip_file) { File.new(File.expand_path('../assets/empty.zip', __FILE__)) }
  let(:guid) { SecureRandom.uuid }

  before do
    RestClient.put("http://#{private_endpoint_ip}/packages/#{guid}", { package: zip_file }, { host: private_endpoint.hostname })
  end

  after do
    RestClient.delete("http://#{private_endpoint_ip}/packages/#{guid}", { host: private_endpoint.hostname })
  end

  context 'by IP address' do
    context 'not passing a host header' do
      it 'responds with 400, because URL is used as host the host is unknown and therefore it is a bad request' do
        expect { RestClient.get("http://#{private_endpoint_ip}/packages/#{guid}", {}) }.to raise_error(RestClient::BadRequest)
      end
    end

    context 'passing header "host: <public_endpoint>"' do
      it 'responds with 404, because host is public and the public host does not allow unsigned access to packages' do
        pending("See https://www.pivotaltracker.com/story/show/126851165")
        expect { RestClient.get("http://#{private_endpoint_ip}/packages/#{guid}", { host: public_endpoint.hostname }) }.to raise_error(RestClient::ResourceNotFound)
      end
    end
  end

  context 'by private endpoint' do
    context 'passing header "host: <public_endpoint>"' do
      it 'responds with 404, because host is public and the public host does not allow unsigned access to packages' do
        pending("See https://www.pivotaltracker.com/story/show/126851165")
        expect { RestClient.get("#{private_endpoint}/packages/#{guid}", { host: public_endpoint.hostname }) }.to raise_error(RestClient::ResourceNotFound)
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
        pending("See https://www.pivotaltracker.com/story/show/126851165")
        expect { RestClient.get("#{public_endpoint}/packages/#{guid}", {}) }.to raise_error(RestClient::ResourceNotFound)
      end
    end

    context 'passing header "host: <public_endpoint>"' do
      it 'responds with 404, because host is public and the public host does not allow unsigned access to packages' do
        pending("See https://www.pivotaltracker.com/story/show/126851165")
        expect { RestClient.get("#{public_endpoint}/packages/#{guid}", { host: public_endpoint.hostname }) }.to raise_error(RestClient::ResourceNotFound)
      end
    end
  end
end
