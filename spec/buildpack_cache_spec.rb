# frozen_string_literal: true

require 'spec_helper'

require 'support/environment'
require 'support/manifest'

RSpec.configure {
  include EnvironmentHelpers
  include ManifestHelpers
}

describe 'buildpack cache resource', type: :integration do
  let(:zip_filepath) { File.expand_path('../assets/empty.zip', __FILE__) }
  let(:zip_file) do
    File.new(zip_filepath)
  end
  let(:upload_body) { { buildpack_cache: zip_file } }
  let(:app_guid) { SecureRandom.uuid }
  let(:app_name) { "#{app_guid}/linux" }
  let(:path) { '/buildpack_cache/entries/' + app_name }

  after action: :upload do
    response = make_delete_request('/buildpack_cache/entries/')
    expect(response.code).to eq(204)
  end

  describe 'PUT /buildpack_cache/entries/:app_guid/:stack_name', action: :upload do
    it 'stores the blob and returns HTTP status 201' do
      response = make_get_request(path)
      expect(response.code).to eq(404)

      response = make_put_request(path, upload_body)
      expect(response.code).to eq(201)

      response = make_get_request(path)
      expect(response.code).to eq(200)
    end

    context 'when the request body is invalid', action: false do
      it 'returns HTTP status 415' do
        response = make_put_request(path, {})
        expect(response.code).to eq(400)
      end
    end
  end

  describe 'DELETE specific entry for /buildpack_cache/entries/:app_guid/:stack_name' do
    context 'when deleting an known file' do
      it 'deletes the blob and returns HTTP status 204' do
        response = make_put_request(path, upload_body)
        expect(response.code).to eq(201)
        response = make_get_request(path)
        expect(response.code).to eq(200)

        response = make_delete_request(path)
        expect(response.code).to eq(204)

        response = make_get_request(path)
        expect(response.code).to eq(404)
      end
    end

    context 'when deleting an unknown file' do
      let(:path) { '/buildpack_cache/entries/unknown_app/linux' }

      it 'returns HTTP status 404' do
        response = make_delete_request(path)
        expect(response).to be_a_404
      end
    end
  end

  describe 'DELETE all entries for /buildpack_cache/entries/:app_guid' do
    let(:delete_path) { '/buildpack_cache/entries/' + app_guid }
    context 'when deleting an known file' do
      before do
        response = make_put_request(path, upload_body)
        expect(response.code).to eq(201)
      end

      it 'deletes the blob and returns HTTP status 204' do
        response = make_delete_request(delete_path)
        expect(response.code).to eq(204)

        response = make_get_request(delete_path)
        expect(response.code).to eq(404)
      end
    end

    context 'when deleting an unknown file' do
      let(:path) { '/buildpack_cache/entries/unknown_app' }

      it 'returns HTTP status 204' do
        response = make_get_request(path)
        expect(response.code).to eq(404)

        response = make_delete_request(path)
        expect(response.code).to eq(204)
      end
    end
  end

  describe 'DELETE /buildpack_cache/entries' do
    let(:key1) { "#{SecureRandom.uuid}/some-stack-name" }
    let(:key2) { "#{SecureRandom.uuid}/some-stack-name" }

    before do
      [key1, key2].each do |key|
        response = make_put_request("/buildpack_cache/entries/#{key}", { buildpack_cache: File.new(zip_filepath) })
        expect(response.code).to eq(201)
      end
    end

    it 'removes all the stored files and returns HTTP status 204' do
      response = make_delete_request('/buildpack_cache/entries')
      expect(response.code).to eq(204)

      [key1, key2].each { |key|
        response = make_get_request("/buildpack_cache/entries/#{key}")
        expect(response.code).to eq(404)
      }
    end
  end

  describe 'GET /buildpack_cache/entries/:app_guid/:stack_name' do
    context 'when getting a known file', action: :upload do
      before do
        make_put_request(path, upload_body)
      end

      it 'returns HTTP status 200' do
        response = make_get_request(path)
        expect(response.code).to eq(200)
      end

      it 'returns the correct contents' do
        response = make_get_request(path)
        expect(response.body).to eq File.open(zip_filepath, 'rb').read
      end
    end

    context 'when getting an unknown file' do
      let(:path) { '/buildpack_cache/entries/unknown_app/linux' }

      it 'returns HTTP status 404' do
        response = make_get_request(path)
        expect(response.code).to eq(404)
      end

      it 'returns the correct error' do
        response = make_get_request(path)
        expect(response).to be_a_404
      end
    end
  end
end
