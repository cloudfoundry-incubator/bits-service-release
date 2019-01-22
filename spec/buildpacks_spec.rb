# frozen_string_literal: true

require 'spec_helper'

describe 'buildpacks resource', type: :integration do
  let(:guid) { SecureRandom.uuid }
  let(:resource_path) { "/buildpacks/#{guid}" }
  let(:zip_filepath) { File.expand_path('../assets/empty.zip', __FILE__) }
  let(:upload_body) { { buildpack: zip_file } }
  let(:zip_file) do
    File.new(zip_filepath)
  end
  let(:existing_guid) do
    SecureRandom.uuid.tap do |guid|
      make_put_request "/buildpacks/#{guid}", upload_body
    end
  end

  after action: :upload do
    response = make_delete_request resource_path
    expect(response.code).to eq(404).or(eq(204))
end

  describe 'PUT /buildpacks/:guid', action: :upload do
    it 'stores the blob in the backend and returns HTTP status 201' do
      response = make_put_request resource_path, upload_body
      expect(response.code).to eq 201

      response = make_get_request resource_path
      expect(response.code).to eq 200
    end
  end

  describe 'GET /buildpacks/:guid' do
    context 'when the buildpack exists', action: :upload do
      let(:guid) { existing_guid } # in order for `after` cleanup to work
      let(:resource_path) { "/buildpacks/#{existing_guid}" }

      it 'returns HTTP status 200 and the correct contents' do
        response = make_get_request resource_path

        expect(response.code).to eq 200
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

      it 'deletes the blob from the backend and returns HTTP status 204' do
        response = make_delete_request resource_path
        expect(response.code).to eq 204

        response = make_get_request resource_path
        expect(response.code).to eq 404
      end
    end

    context 'when the buildpack does not exist' do
      let(:resource_path) { '/buildpacks/not-existing' }

      it 'has HTTP 404 as status code' do
        response = make_delete_request resource_path
        expect(response.code).to eq 404
      end
    end
  end
end
