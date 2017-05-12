require 'spec_helper'
require 'shared_examples'

describe 'packages resource' do
  let(:guid) { SecureRandom.uuid }
  let(:resource_path) { "/packages/#{guid}" }
  let(:upload_body) { { package: zip_file } }
  let(:blobstore_client) { backend_client(:packages) }
  let(:zip_filepath) { File.expand_path('../assets/empty.zip', __FILE__) }
  let(:zip_file) { File.new(zip_filepath) }
  let(:existing_guid) do
    SecureRandom.uuid.tap do |guid|
      make_put_request "/packages/#{guid}", upload_body
    end
  end

  describe 'PUT /packages/:guid', type: :integration do
    context 'when package is uploaded' do
      it 'returns HTTP status 201' do
        response = make_put_request resource_path, upload_body
        expect(response.code).to eq 201
      end

      it 'stores the blob in the backend' do
        make_put_request resource_path, upload_body
        expect(blobstore_client.key_exist?(guid)).to eq(true)
      end

      context 'when the request body is invalid' do
        let(:upload_body) { Hash.new }

        it 'returns HTTP status 4XX' do
          response = make_put_request resource_path, upload_body
          expect(response.code).to eq 400
        end
      end

      include_examples 'when blobstore disk is full', :packages
    end

    context 'when package is duplicated' do
      context 'when the package exists' do
        it 'returns HTTP status 201' do
          response = make_put_request resource_path, JSON.generate(source_guid: existing_guid)
          expect(response.code).to eq 201
        end

        it 'returns the guid and the package exists' do
          make_put_request resource_path, JSON.generate(source_guid: existing_guid)
          expect(blobstore_client.key_exist?(guid)).to eq(true)
        end

        context 'when the package does not exist' do
          it 'returns the correct error' do
            response = make_put_request resource_path, JSON.generate(source_guid: 'invalid-guid')
            expect(response).to be_a_404
          end
        end

        context 'when the body is invalid' do
          it 'returns the correct error' do
            response = make_put_request resource_path, 'foobar'
            expect(response.code).to eq(400)
          end
        end

        context 'when the body is empty' do
          it 'returns the correct error' do
            response = make_put_request resource_path, ''
            expect(response.code).to eq(400)
          end
        end
      end
    end

    context 'when the PUT is not a multipart request' do
      let(:upload_body) { Hash.new }

      it 'returns HTTP status 4XX' do
        response = make_put_request resource_path, upload_body
        expect(response.code).to eq 400
      end
    end
  end

  describe 'GET /packages/:guid', type: :integration do
    context 'when the package exists' do
      let(:resource_path) { "/packages/#{existing_guid}" }

      it 'returns HTTP status 200' do
        response = make_get_request resource_path
        expect(response.code).to eq 200
      end

      it 'returns the correct contents' do
        response = make_get_request resource_path
        expect(response.body).to eq File.open(zip_filepath, 'rb').read
      end
    end

    context 'when the package does not exist' do
      let(:resource_path) { '/packages/not-existing' }

      it 'returns the correct error' do
        response = make_get_request resource_path
        expect(response).to be_a_404
      end
    end
  end

  describe 'DELETE /packages/:guid', type: :integration do
    context 'when the package exists' do
      let(:resource_path) { "/packages/#{existing_guid}" }

      it 'returns HTTP status 204' do
        response = make_delete_request resource_path
        expect(response.code).to eq 204
      end

      it 'deletes the blob from the backend' do
        make_delete_request resource_path
        expect(blobstore_client.key_exist?(guid)).to eq(false)
      end
    end

    context 'when the package does not exist' do
      let(:resource_path) { '/packages/not-existing' }

      it 'has HTTP 404 as status code' do
        response = make_delete_request resource_path
        expect(response.code).to eq 404
      end

      it 'returns the correct error' do
        response = make_delete_request resource_path
        expect(response).to be_a_404
      end
    end
  end
end
