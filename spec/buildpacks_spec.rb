# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples'

describe 'buildpacks resource', type: :integration do
  let(:guid) { SecureRandom.uuid }
  let(:resource_path) { "/buildpacks/#{guid}" }
  let(:zip_filepath) { File.expand_path('../assets/empty.zip', __FILE__) }
  let(:upload_body) { { buildpack: zip_file } }
  let(:blobstore_client) { backend_client(:buildpacks) }
  let(:zip_file) do
    File.new(zip_filepath)
  end
  let(:existing_guid) do
    SecureRandom.uuid.tap do |guid|
      make_put_request "/buildpacks/#{guid}", upload_body
    end
  end

  after action: :upload do
    expect(blobstore_client.delete_resource(guid)).to be_truthy
    expect(blobstore_client.key_exist?(guid)).to eq(false)
  end

  describe 'PUT /buildpacks/:guid', action: :upload do
    it 'returns HTTP status 201' do
      response = make_put_request resource_path, upload_body
      expect(response.code).to eq 201
    end

    it 'stores the blob in the backend' do
      make_put_request resource_path, upload_body
      expect(blobstore_client.key_exist?(guid)).to eq(true)
    end

    include_examples 'when blobstore disk is full', :buildpacks
  end

  describe 'GET /buildpacks/:guid' do
    context 'when the buildpack exists', action: :upload do
      let(:guid) { existing_guid } # in order for `after` cleanup to work
      let(:resource_path) { "/buildpacks/#{existing_guid}" }

      it 'returns HTTP status 200' do
        response = make_get_request resource_path
        expect(response.code).to eq 200
      end

      it 'returns the correct contents' do
        response = make_get_request resource_path
        expect(response.body).to eq File.open(zip_filepath, 'rb').read
      end
    end

    context 'when the buildpack does not exist' do
      let(:resource_path) { '/buildpacks/not-existing' }

      it 'returns the correct error' do
        response = make_get_request resource_path
        expect(response).to be_a_404
      end
    end
  end

  describe 'DELETE /buildpacks/:guid' do
    context 'when the buildpack exists' do
      let(:resource_path) { "/buildpacks/#{existing_guid}" }

      it 'returns HTTP status 204' do
        response = make_delete_request resource_path
        expect(response.code).to eq 204
      end

      it 'deletes the blob from the backend' do
        make_delete_request resource_path
        expect(blobstore_client.key_exist?(guid)).to eq(false)
      end
    end

    context 'when the buildpack does not exist' do
      let(:resource_path) { '/buildpacks/not-existing' }

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
