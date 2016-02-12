require 'spec_helper'

describe 'buildpacks resource' do
  let(:guid) { SecureRandom.uuid }

  let(:request_path) { "/buildpacks/#{guid}" }

  let(:zip_filepath) { File.expand_path("../assets/empty.zip", __FILE__)}

  let(:zip_file) do
    File.new(zip_filepath)
  end

  let(:upload_body) { { buildpack: zip_file } }

  describe 'PUT /buildpacks/:guid', type: :integration do
    it 'returns HTTP status 201' do
      response = make_put_request request_path, upload_body
      expect(response.code).to eq 201
    end

    context 'when the request body is invalid' do
      let(:upload_body) { Hash.new }

      it 'returns HTTP status 415' do
        response = make_put_request request_path, upload_body
        expect(response.code).to eq 415
      end
    end

    context 'when the uploaded file is not a zip file' do
      let(:upload_body) { { buildpack: __FILE__ } }

      it 'returns HTTP status 415' do
        response = make_put_request request_path, upload_body
        expect(response.code).to eq 415
      end
    end
  end

  describe 'GET /buildpacks/:guid', type: :integration do
    context 'when the buildpack exists' do
      before(:each) do
        make_put_request request_path, upload_body
      end

      it 'returns HTTP status 200' do
        response = make_get_request request_path
        expect(response.code).to eq 200
      end

      it 'returns the correct contents' do
        response = make_get_request request_path
        expect(response.body).to eq File.open(zip_filepath, 'rb').read
      end
    end

    context 'when the buildpack does not exist' do
      it 'returns the correct error' do
        response = make_get_request request_path

        expect(response.code).to eq 404
        json = MultiJson.load(response.body)
        expect(json['code']).to eq(10000)
        expect(json['description']).to match(/Unknown request/)
      end
    end
  end
end
