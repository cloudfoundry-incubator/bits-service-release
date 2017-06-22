require 'spec_helper'

shared_examples 'when blobstore disk is full' do |resource|
  context 'when blobstore disk is full', if: blobstore_provider(resource) == 'local', action: false do
    before { expect(blobstore_client.fill_storage).to be true }
    after { blobstore_client.clear_storage }

    it 'returns HTTP status 507' do
      response = case resource
                 when :app_stash
                   make_post_request endpoint, request_body
                 when :buildpack_cache
                   make_put_request path, upload_body
                 when :buildpacks, :droplets, :packages
                   make_put_request resource_path, upload_body
                 else
                   warn 'Unknown resource type'
                 end

      expect(response.code).to eq 507
      expect(response.body).not_to be_empty
      payload = JSON(response.body)
      expect(payload['code']).to eq 500000
    end
  end
end
