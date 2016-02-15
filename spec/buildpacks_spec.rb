require 'spec_helper'

describe 'buildpacks resource' do
  let(:guid) { SecureRandom.uuid }

  let(:collection_path) { '/buildpacks' }

  let(:resource_path) { "/buildpacks/#{existing_guid}" }

  let(:existing_guid) do
    response = make_post_request collection_path, upload_body
    JSON.parse(response.body)['guid']
  end

  let(:zip_filepath) { File.expand_path("../assets/empty.zip", __FILE__)}

  let(:zip_file) do
    File.new(zip_filepath)
  end

  let(:upload_body) { { buildpack: zip_file } }

  describe 'POST /buildpacks', type: :integration do
    it 'returns HTTP status 201' do
      response = make_post_request collection_path, upload_body
      expect(response.code).to eq 201
    end

    context 'when the request body is invalid' do
      let(:upload_body) { Hash.new }

      it 'returns HTTP status 415' do
        response = make_post_request collection_path, upload_body
        expect(response.code).to eq 415
      end
    end

    context 'when the uploaded file is not a zip file' do
      let(:upload_body) { { buildpack: __FILE__ } }

      it 'returns HTTP status 415' do
        response = make_post_request collection_path, upload_body
        expect(response.code).to eq 415
      end
    end
  end

  describe 'GET /buildpacks/:guid', type: :integration do
    context 'when the buildpack exists' do
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

        expect(response.code).to eq 404
        json = JSON.parse(response.body)
        expect(json['code']).to eq(10000)
        expect(json['description']).to match(/Unknown request/)
      end
    end
  end
end
