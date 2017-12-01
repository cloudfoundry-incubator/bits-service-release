# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples'

describe 'buildpack cache resource', type: :integration do
  let(:zip_filepath) { File.expand_path('../assets/empty.zip', __FILE__) }
  let(:zip_file) do
    File.new(zip_filepath)
  end
  let(:upload_body) { { buildpack_cache: zip_file } }
  let(:blobstore_client) { backend_client(:buildpack_cache) }

  let(:app_guid) { SecureRandom.uuid }
  let(:app_name) { "#{app_guid}/linux" }
  let(:path) { '/buildpack_cache/entries/' + app_name }

  after action: :upload do
    expect(blobstore_client.delete_resource(app_name)).to be_truthy
    expect(blobstore_client.key_exist?(app_name)).to eq(false)
  end

  describe 'PUT /buildpack_cache/entries/:app_guid/:stack_name', action: :upload do
    it 'returns HTTP status 201' do
      response = make_put_request(path, upload_body)
      expect(response.code).to eq(201)
    end

    it 'stores the blob in the backend' do
      make_put_request(path, upload_body)
      expect(blobstore_client.key_exist?(app_name)).to eq(true)
    end

    context 'when the request body is invalid', action: false do
      it 'returns HTTP status 415' do
        response = make_put_request(path, {})
        expect(response.code).to eq(415)
      end
    end

    include_examples 'when blobstore disk is full', :buildpack_cache
  end

  describe 'DELETE specific entry for /buildpack_cache/entries/:app_guid/:stack_name' do
    context 'when deleting an known file' do
      before do
        make_put_request(path, upload_body)
      end

      it 'returns HTTP status 204' do
        response = make_delete_request(path)
        expect(response.code).to eq(204)
      end

      it 'deletes the blob from the backend' do
        make_delete_request(path)
        expect(blobstore_client.key_exist?(app_name)).to eq(false)
      end
    end

    context 'when deleting an unknown file' do
      let(:path) { '/buildpack_cache/entries/unknown_app/linux' }

      it 'returns HTTP status 404' do
        response = make_delete_request(path)
        expect(response).to be_a_404
      end

      it 'returns the correct error' do
        response = make_delete_request(path)
        expect(response).to be_a_404
      end
    end
  end

  describe 'DELETE all entries for /buildpack_cache/entries/:app_guid' do
    let(:delete_path) { '/buildpack_cache/entries/' + app_guid }
    context 'when deleting an known file' do
      before do
        make_put_request(path, upload_body)
      end

      it 'returns HTTP status 204' do
        response = make_delete_request(delete_path)
        expect(response.code).to eq(204)
      end

      it 'deletes the blob from the backend' do
        make_delete_request(delete_path)
        expect(blobstore_client.key_exist?(app_name)).to eq(false)
      end
    end

    context 'when deleting an unknown file' do
      let(:path) { '/buildpack_cache/entries/unknown_app' }

      it 'returns HTTP status 204' do
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
        make_put_request("/buildpack_cache/entries/#{key}", { buildpack_cache: File.new(zip_filepath) })
      end
    end

    it 'returns HTTP status 204' do
      response = make_delete_request('/buildpack_cache/entries')
      expect(response.code).to eq(204)
    end

    it 'removes all the stored files' do
      [key1, key2].each { |key| expect(blobstore_client.key_exist?(key)).to eq(true) }
      make_delete_request('/buildpack_cache/entries')
      [key1, key2].each { |key| expect(blobstore_client.key_exist?(key)).to eq(false) }
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
