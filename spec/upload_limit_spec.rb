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
    write_to_file(filepath_small, size_in_bytes: 1024 * 1024) #1M
    File.new(filepath_small)
  end
  let(:file_big) do
    write_to_file(filepath_big, size_in_bytes: 6 * 1024 * 1024) #6M
    File.new(filepath_big)
  end

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
        response = make_put_request(resource_path, upload_body_big)
        expect(response.code).to eq 413
      end
    end
  end

  context 'buildpack_cache/entries' do
    let(:resource_path) { "/buildpack_cache/entries/#{SecureRandom.uuid}/cflinux" }
    let(:upload_body_small) { { buildpack_cache: file_small } }
    let(:upload_body_big) { { buildpack_cache: file_big } }
    let(:method) { :PUT }

    include_examples 'limited file upload'
  end

  context 'buildpacks' do
    let(:resource_path) { "/buildpacks/#{SecureRandom.uuid}" }
    let(:upload_body_small) { { buildpack: file_small } }
    let(:upload_body_big) { { buildpack: file_big } }
    let(:method) { :PUT }

    include_examples 'limited file upload'
  end

  context 'packages' do
    let(:resource_path) { "/packages/#{SecureRandom.uuid}" }
    let(:upload_body_small) { { package: file_small } }
    let(:upload_body_big) { { package: file_big } }
    let(:method) { :PUT }

    include_examples 'limited file upload'
  end

  context 'droplets' do
    let(:resource_path) { "/droplets/#{SecureRandom.uuid}/#{SecureRandom.uuid}" }
    let(:upload_body_small) { { droplet: file_small } }
    let(:upload_body_big) { { droplet: file_big } }
    let(:method) { :PUT }

    include_examples 'limited file upload'
  end

  context 'app_stash/entries' do
    let(:resource_path) { "/app_stash/entries" }
    let(:upload_body_small) { { application: File.new(File.expand_path('../assets/app.zip', __FILE__)) } }
    let(:upload_body_big) { { application: file_big } }
    let(:method) { :POST }

    include_examples 'limited file upload'
  end
end
