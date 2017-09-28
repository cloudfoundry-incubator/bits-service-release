require 'spec_helper'
require 'support/cf.rb'

describe 'Upload limits for resources', type: 'limits' do
  before :all do
    @tmp_dir = Dir.mktmpdir
  end
  after :all do
    FileUtils.remove_entry(@tmp_dir)
  end

  let(:filepath_small) { File.join(@tmp_dir, 'small-file.zip') }
  let(:filepath_big) { File.join(@tmp_dir, 'big-file.zip') }
  let(:file_small) do
    # Should be below specific threshold. See templates/body-size-stub.yml
    write_to_file(filepath_small, size_in_bytes: file_size_small)
    File.new(filepath_small)
  end
  let(:file_big) do
    # Should be above specific threshold. See templates/body-size-stub.yml
    write_to_file(filepath_big, size_in_bytes: file_size_big)
    File.new(filepath_big)
  end
  let(:upload_body_small) { { upload_field => file_small } }
  let(:upload_body_big) { { upload_field => file_big } }

  let(:blobstore_client) { backend_client(:app_stash) }
  let(:app_stash_entries) do
    [
      { 'fn' => 'app/app.rb', 'sha1' => '8b381f8864b572841a26266791c64ae97738a659', 'mode' => '777' },
      { 'fn' => 'app/lib.rb', 'sha1' => '594eb15515c89bbfb0874aa4fd4128bee0a1d0b5', 'mode' => '666' }
    ]
  end

  shared_examples 'limited file upload' do
    context 'internal uploads' do
      context 'when the file is smaller than limit' do
        after do
          del_response = make_delete_request resource_path
          expect(del_response.code).to be_between(200, 204)
        end
        it 'returns HTTP status code 201' do
          response = make_put_request(resource_path, upload_body_small)
          expect(response.code).to eq 201
        end
      end

      context 'when the file is bigger than limit' do
        it 'returns HTTP status code 413' do
          response = make_put_request(resource_path, upload_body_big)
          expect(response.code).to eq 413
        end
      end
    end
  end

  shared_examples 'limited signed file upload' do
    context 'signed uploads' do
      context 'when the file is smaller than limit' do
        after do
          del_response = make_delete_request resource_path
          expect(del_response.code).to be_between(200, 204)
        end
        it 'returns HTTP status code 201' do
          sign_url = "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{resource_path}?verb=put"
          response = RestClient::Request.execute({ url: sign_url, method: :get, verify_ssl: OpenSSL::SSL::VERIFY_PEER, ssl_ca_file: ca_cert })
          signed_put_url = response.body.to_s

          response = RestClient::Resource.new(
            signed_put_url,
            verify_ssl: OpenSSL::SSL::VERIFY_PEER,
            ssl_ca_file: ca_cert
          ).put(upload_body_small)
          # response = RestClient.put(signed_put_url, upload_body_small)
          expect(response.code).to eq 201
        end
      end

      context 'when the file is bigger than limit' do
        it 'returns HTTP status code 413' do
          sign_url = "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{resource_path}?verb=put"
          response = RestClient::Request.execute({ url: sign_url, method: :get, verify_ssl: OpenSSL::SSL::VERIFY_PEER, ssl_ca_file: ca_cert })
          signed_put_url = response.body.to_s
          expect {
            RestClient::Resource.new(
              signed_put_url,
              verify_ssl: OpenSSL::SSL::VERIFY_PEER,
              ssl_ca_file: ca_cert
            ).put(upload_body_big)
          }.to raise_error(RestClient::RequestEntityTooLarge)
          # expect { RestClient.put(signed_put_url, upload_body_big) }.to raise_error(RestClient::RequestEntityTooLarge)
        end
      end
    end
  end

  context 'buildpack_cache/entries' do
    let(:resource_path) { "/buildpack_cache/entries/#{SecureRandom.uuid}/cflinux" }
    let(:upload_field) { 'buildpack_cache' }
    let(:file_size_small) { 6.5 * 1024 * 1024 }
    let(:file_size_big) { 7.5 * 1024 * 1024 }

    include_examples 'limited file upload'
    include_examples 'limited signed file upload' if blobstore_provider(:buildpack_cache) == 'local'
  end

  context 'buildpacks' do
    let(:resource_path) { "/buildpacks/#{SecureRandom.uuid}" }
    let(:upload_field) { 'buildpack' }
    let(:file_size_small) { 3.5 * 1024 * 1024 }
    let(:file_size_big) { 4.5 * 1024 * 1024 }

    include_examples 'limited file upload'
    include_examples 'limited signed file upload' if blobstore_provider(:buildpacks) == 'local'
  end

  context 'packages' do
    let(:guid) do
      if !cc_updates_enabled?
        SecureRandom.uuid
      else
        @cf_client.create_package(@app_id)
      end
    end
    before :all do
      if cc_updates_enabled?
        @cf_client = CFClient::Client.new(cc_api_url, cc_user, cc_password)
        @org_id = @cf_client.create_org
        expect(@org_id).to_not be_empty
        @space_id = @cf_client.create_space(@org_id)
        expect(@space_id).to_not be_empty
        @app_id = @cf_client.create_app(@space_id)
        expect(@app_id).to_not be_empty
      end
    end
    after :all do
      if cc_updates_enabled?
        @cf_client.delete_org(@org_id)
        expect(@cf_client.get_org(@org_id)['error_code']).to eq('CF-OrganizationNotFound')
      end
    end
    let(:resource_path) { "/packages/#{guid}" }
    let(:upload_field) { 'package' }
    let(:file_size_small) { 5.5 * 1024 * 1024 }
    let(:file_size_big) { 6.5 * 1024 * 1024 }

    include_examples 'limited file upload'
    include_examples 'limited signed file upload' if blobstore_provider(:packages) == 'local'
  end

  context 'droplets' do
    let(:resource_path) { "/droplets/#{SecureRandom.uuid}/#{SecureRandom.uuid}" }
    let(:upload_field) { 'droplet' }
    let(:file_size_small) { 4.5 * 1024 * 1024 }
    let(:file_size_big) { 5.5 * 1024 * 1024 }

    include_examples 'limited file upload'
    include_examples 'limited signed file upload' if blobstore_provider(:droplets) == 'local'
  end

  context 'app_stash/entries' do
    let(:resource_path) { '/app_stash/entries' }
    let(:upload_field) { 'application' }
    # We need a valid zip for this spec
    let(:file_small) { File.new(File.expand_path('../assets/app.zip', __FILE__)) }
    let(:file_size_big) { 3.5 * 1024 * 1024 }

    context 'when the file is smaller than limit' do
      after do
        app_stash_entries.each do |entry|
          expect(blobstore_client.delete_resource(entry['sha1'])).to be_truthy
          expect(blobstore_client.key_exist?(entry['sha1'])).to eq(false)
        end
      end
      it 'returns HTTP status code 201' do
        response = make_post_request(resource_path, upload_body_small)
        expect(response.code).to eq 201
      end
    end

    context 'when the file is bigger than limit' do
      it 'returns HTTP status code 413' do
        response = make_post_request(resource_path, upload_body_big)
        expect(response.code).to eq 413
      end
    end
  end
end
