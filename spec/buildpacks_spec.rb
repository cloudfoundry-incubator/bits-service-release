require 'spec_helper'

describe 'PUT /buildpack', type: :integration do
  let(:guid) { SecureRandom.uuid }

  let(:zip_filepath) { File.expand_path("../assets/empty.zip", __FILE__)}

  let(:zip_file) do
    File.new(zip_filepath)
  end

  let(:data) { { buildpack: zip_file } }

  it 'returns HTTP status 201' do
    response = RestClient.put "#{bits_service_endpoint}/buildpacks/#{guid}", data
    expect(response.code).to eq 201
  end
end
