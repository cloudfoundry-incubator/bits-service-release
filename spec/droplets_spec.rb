require 'spec_helper'

describe 'droplets resource' do
  let(:guid) { "#{SecureRandom.uuid}/#{SecureRandom.uuid}" }
  let(:resource_path) { "/droplets/#{guid}" }
  let(:zip_filepath) { File.expand_path('../assets/empty.zip', __FILE__) }
  let(:upload_body) { { droplet: zip_file } }
  let(:blobstore_client) { backend_client(:droplets) }
  let(:existing_guid) do
    "#{SecureRandom.uuid}/#{SecureRandom.uuid}".tap do |guid|
      make_put_request "/droplets/#{guid}", upload_body
    end
  end
  let(:zip_file) do
    File.new(zip_filepath)
  end

  describe 'PUT /droplets/:guid', type: :integration do
    it 'returns HTTP status 201' do
      response = make_put_request resource_path, upload_body
      expect(response.code).to eq 201
    end

    it 'stores the blob in the backend' do
      response = make_put_request resource_path, upload_body
      expect(blobstore_client.key_exist?(guid)).to eq(true)
    end

    context 'when the request body is invalid' do
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
    context 'when the droplet exists' do
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

      it 'returns HTTP status 204' do
        response = make_delete_request resource_path
        expect(response.code).to eq 204
      end

      it 'deletes the blob from the backend' do
        make_delete_request resource_path
        expect(blobstore_client.key_exist?(guid)).to eq(false)
      end
    end

    context 'when the droplet does not exist' do
      let(:resource_path) { '/droplets/not-existing/droplet' }

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
