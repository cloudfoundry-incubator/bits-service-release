require 'spec_helper'

describe 'packages resource' do
  let(:guid) { SecureRandom.uuid }

  let(:collection_path) { '/packages' }

  let(:resource_path) { "/packages/#{existing_guid}" }

  let(:existing_guid) do
    response = make_post_request collection_path, upload_body
    JSON.parse(response.body)['guid']
  end

  let(:zip_filepath) { File.expand_path('../assets/empty.zip', __FILE__) }

  let(:zip_file) do
    File.new(zip_filepath)
  end

  let(:upload_body) { { package: zip_file } }

  let(:blobstore_client) { backend_client(:packages) }

  describe 'POST /packages', type: :integration do
    context 'when package is uploaded' do
      it 'returns HTTP status 201' do
        response = make_post_request collection_path, upload_body
        expect(response.code).to eq 201
      end

      it 'stores the blob in the backend' do
        response = make_post_request collection_path, upload_body
        guid = guid_from_response(response)
        expect(blobstore_client.key_exist?(guid)).to eq(true)
      end

      context 'when the request body is invalid' do
        let(:upload_body) { Hash.new }

        it 'returns HTTP status 4XX' do
          response = make_post_request collection_path, upload_body
          expect(response.code).to eq 400
        end
      end
    end

    context 'when package is duplicated' do
      context 'when the package exists' do
        it 'returns HTTP status 201' do
          response = make_post_request collection_path, JSON.generate(source_guid: existing_guid)
          expect(response.code).to eq 201
        end

        it 'returns the guid and the package exists' do
          response = make_post_request collection_path, JSON.generate(source_guid: existing_guid)
          guid = guid_from_response(response)
          expect(blobstore_client.key_exist?(guid)).to eq(true)
        end

        context 'when the package does not exist' do
          it 'returns the correct error' do
            response = make_post_request collection_path, JSON.generate(source_guid: 'invalid-guid')
            expect(response).to be_a_404
          end
        end

        context 'when the body is invalid' do
          it 'returns the correct error' do
            response = make_post_request collection_path, 'foobar'
            expect(response.code).to eq(400)
          end
        end

        context 'when the body is empty' do
          it 'returns the correct error' do
            response = make_post_request collection_path, ''
            expect(response.code).to eq(400)
          end
        end
      end
    end

    context 'when the POST is not a multipart request' do
      let(:upload_body) { Hash.new }

      it 'returns HTTP status 4XX' do
        response = make_post_request collection_path, upload_body
        expect(response.code).to eq 400
      end
    end
  end

  describe 'GET /packages/:guid', type: :integration do
    context 'when the package exists' do
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
