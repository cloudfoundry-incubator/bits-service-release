# frozen_string_literal: true

require 'spec_helper'
require 'support/http'

RSpec.configure {
  include HttpHelpers
}

describe 'droplets resource' do
  let(:guid) { "#{SecureRandom.uuid}/#{SecureRandom.uuid}" }
  let(:resource_path) { "/droplets/#{guid}" }
  let(:zip_filepath) { File.expand_path('../assets/empty.zip', __FILE__) }
  let(:upload_body) { { droplet: zip_file } }
  let(:existing_guid) do
    "#{SecureRandom.uuid}/#{SecureRandom.uuid}".tap do |guid|
      make_put_request "/droplets/#{guid}", upload_body
    end
  end
  let(:zip_file) do
    File.new(zip_filepath)
  end

  after action: :upload do
    response = make_delete_request resource_path
    expect(response.code).to eq(404).or(eq(204))
  end

  describe 'public signed endpoints', type: :integration, action: :upload do
    let(:guid) { SecureRandom.uuid.to_s }
    let(:path) { "/droplets/#{guid}" }

    context 'PUT /sign/droplets/:guid' do
      context 'with content_type is configured' do
        it 'returns HTTP status 201' do
          signed_droplet_url = signed_url_for_droplets_puts(path)
          response = rest_request(signed_droplet_url).put zip_file, content_type: 'application/octet-stream'
          expect(response.code).to eq 201
        end
      end
      context 'minimal request config' do
        it 'returns HTTP status 201' do
          signed_droplet_url = signed_url_for_droplets_puts(path)
          response = rest_request(signed_droplet_url).put zip_file
          expect(response.code).to eq 201
        end
      end

      context 'missing Digest', action: false do
        it 'returns HTTP status 400' do
          droplet_url = signed_url_for_droplets_puts(path)
          expect { RestClient::Resource.new(
            droplet_url,
            verify_ssl: OpenSSL::SSL::VERIFY_PEER,
            ssl_cert_store: cert_store,
          ).put zip_file
          }.to raise_error(RestClient::BadRequest)
        end
      end

      context 'digest malformed', action: false do
        let(:digest) { '' }

        it 'returns the right error code' do
          droplet_url = signed_url_for_droplets_puts(path)
          expect {
            RestClient::Resource.new(
              droplet_url,
              verify_ssl: OpenSSL::SSL::VERIFY_PEER,
              ssl_cert_store: cert_store,
              headers: {
                Digest: digest,
              },
            ).put zip_file
          }.to raise_error(RestClient::BadRequest) do |error|
            code = JSON.parse(error.http_body)['code']
            expect(code).to eq 290003
          end
        end
      end

      def rest_request(signed_droplet_url)
        RestClient::Resource.new(
          signed_droplet_url,
          verify_ssl: OpenSSL::SSL::VERIFY_PEER,
          ssl_cert_store: cert_store,
          headers: {
            Digest: 'Sha256=abcdefg',
          },
        )
      end

      def signed_url_for_droplets_puts(path)
        droplet_url = RestClient::Request.execute({
          url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}:#{private_endpoint.port}/sign#{path}?verb=put",
          method: :get,
          verify_ssl: OpenSSL::SSL::VERIFY_PEER,
          ssl_cert_store: cert_store
          })
        expect(droplet_url.code).to eq 200
        droplet_url
      end
    end
  end

  describe 'internal endpoint' do
    describe 'PUT /droplets/:guid/:digest', type: :integration, action: :upload do
      it 'stores the blob in the backend and returns HTTP status 201' do
        response = make_put_request resource_path, upload_body
        expect(response.code).to eq 201

        response = make_get_request resource_path
        expect(response.code).to eq 200
      end

      context 'when the request body is invalid', action: false do
        let(:tempfile) {
          @f = Tempfile.new('xxx')
        }

        after :each do
          @f.unlink
        end

        let(:upload_body) { { buildpack: tempfile } }

        it 'returns HTTP status 4XX' do
          response = make_put_request resource_path, upload_body
          expect(response.code).to eq 400
        end
      end
    end

    describe 'GET /droplets/:guid', type: :integration do
      context 'when the droplet exists', action: :upload do
        let(:guid) { existing_guid }

        it 'returns HTTP status 200' do
          response = make_get_request resource_path
          expect(response.code).to eq 200
        end

        it 'returns the correct contents' do
          response = make_get_request resource_path
          expect(response.body).to eq File.open(zip_filepath, 'rb').read
        end
      end

      context 'when the droplet does not exist' do
        let(:resource_path) { '/droplets/not-existing/droplet' }

        it 'returns the correct error' do
          response = make_get_request resource_path
          expect(response).to be_a_404
        end
      end
    end

    describe 'DELETE /droplets/:guid', type: :integration do
      context 'when the droplet exists' do
        let(:guid) { existing_guid }

        it 'deletes the blob from the backend and returns HTTP status 204' do
          response = make_delete_request resource_path
          expect(response.code).to eq 204

          response = make_get_request resource_path
          expect(response.code).to eq 404
        end
      end

      context 'when the droplet does not exist' do
        let(:resource_path) { '/droplets/not-existing/droplet' }

        it 'has HTTP 404 as status code' do
          response = make_delete_request resource_path
          expect(response.code).to eq 404
        end
      end
    end
  end
end
