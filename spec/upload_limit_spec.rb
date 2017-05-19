require 'spec_helper'

describe 'Upload limits for resources' do
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

  shared_examples 'limited file upload' do
    context 'when the file is smaller then limit' do
      it 'returns HTTP status code 201' do
        response = make_put_request(resource_path, upload_body_small) if method == :PUT
        response = make_post_request(resource_path, upload_body_small) if method == :POST

        expect(response.code).to eq 201
      end
    end

    context 'when the file is bigger then limit' do
      it 'returns HTTP status code 413' do
        response = make_put_request(resource_path, upload_body_big) if method == :PUT
        response = make_post_request(resource_path, upload_body_big) if method == :POST

        expect(response.code).to eq 413
      end
    end
  end

  shared_examples 'limited signed file upload' do
    context 'when the file is smaller then limit' do
      it 'returns HTTP status code 201' do
        response = RestClient.get("http://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{resource_path}?verb=#{method.to_s.downcase}")
        signed_put_url = response.body.to_s

        response = RestClient.put(signed_put_url, upload_body_small)

        expect(response.code).to eq 201
      end
    end

    context 'when the file is bigger then limit' do
      it 'returns HTTP status code 413' do
        sign_url = "http://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{resource_path}?verb=put"
        response = RestClient.get(sign_url)
        signed_put_url = response.body.to_s

        expect { RestClient.put(signed_put_url, upload_body_big) }.to raise_error(RestClient::RequestEntityTooLarge)
      end
    end
  end

  context 'buildpack_cache/entries' do
    let(:resource_path) { "/buildpack_cache/entries/#{SecureRandom.uuid}/cflinux" }
    let(:method) { :PUT }
    let(:upload_field) { 'buildpack_cache' }
    let(:file_size_small) { 6.5 * 1024 * 1024 }
    let(:file_size_big) { 7.5 * 1024 * 1024 }

    include_examples 'limited file upload'
    include_examples 'limited signed file upload'
  end

  context 'buildpacks' do
    let(:resource_path) { "/buildpacks/#{SecureRandom.uuid}" }
    let(:method) { :PUT }
    let(:upload_field) { 'buildpack' }
    let(:file_size_small) { 3.5 * 1024 * 1024 }
    let(:file_size_big) { 4.5 * 1024 * 1024 }

    include_examples 'limited file upload'
    include_examples 'limited signed file upload'
  end

  context 'packages' do
    let(:resource_path) { "/packages/#{SecureRandom.uuid}" }
    let(:method) { :PUT }
    let(:upload_field) { 'package' }
    let(:file_size_small) { 5.5 * 1024 * 1024 }
    let(:file_size_big) { 6.5 * 1024 * 1024 }

    include_examples 'limited file upload'
    include_examples 'limited signed file upload'
  end

  context 'droplets' do
    let(:resource_path) { "/droplets/#{SecureRandom.uuid}/#{SecureRandom.uuid}" }
    let(:method) { :PUT }
    let(:upload_field) { 'droplet' }
    let(:file_size_small) { 4.5 * 1024 * 1024 }
    let(:file_size_big) { 5.5 * 1024 * 1024 }

    include_examples 'limited file upload'
    include_examples 'limited signed file upload'
  end

  context 'app_stash/entries' do
    let(:resource_path) { '/app_stash/entries' }
    let(:method) { :POST }
    let(:upload_field) { 'application' }
    # We need a valid zip for this spec
    let(:file_small) { File.new(File.expand_path('../assets/app.zip', __FILE__)) }
    let(:file_size_big) { 3.5 * 1024 * 1024 }

    include_examples 'limited file upload'
  end
end
