# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples'

describe 'app_stash endpoint' do
  let(:blobstore_client) { backend_client(:app_stash) }

  let(:app_stash_zip_path) { File.expand_path('../assets/app.zip', __FILE__) }
  let(:app_stash_entries) do
    [
      { 'fn' => 'app/app.rb', 'sha1' => '8b381f8864b572841a26266791c64ae97738a659', 'mode' => '777' },
      { 'fn' => 'app/lib.rb', 'sha1' => '594eb15515c89bbfb0874aa4fd4128bee0a1d0b5', 'mode' => '666' }
    ]
  end

  after action: :upload do
    app_stash_entries.each do |entry|
      expect(blobstore_client.delete_resource(entry['sha1'])).to be_truthy
      expect(blobstore_client.key_exist?(entry['sha1'])).to eq(false)
    end
  end

  describe 'POST /app_stash/entries', { type: :integration, action: :upload } do
    let(:endpoint) { '/app_stash/entries' }
    let(:request_body) { { application: File.new(app_stash_zip_path) } }

    it 'returns HTTP status 201 and stores the blob in the backend' do
      response = make_post_request endpoint, request_body

      expect(response.code).to eq 201
      app_stash_entries.each do |entry|
        expect(blobstore_client.key_exist?(entry['sha1'])).to eq(true)
      end
    end

    it 'returns a json with the reciept of the stored zip' do
      response = make_post_request endpoint, request_body
      receipt = JSON.parse(response.body)

      expect(receipt).to be_a(Array)
      app_stash_entries.each do |entry|
        expect(receipt).to include(entry)
      end
    end

    context 'when the uploaded file is not a zip file', action: false do
      let(:request_body) { { application: File.new(__FILE__) } }

      it 'returns HTTP status 4XX' do
        response = make_post_request endpoint, request_body
        expect(response.code).to eq 400
      end
    end

    context 'when the files are really new and space needs to be allocated' do
      let(:tmp_dir) { Dir.mktmpdir }
      let(:filepath) { File.join(tmp_dir, 'file') }
      let(:zip_path) { File.join(tmp_dir, 'file.zip') }
      let(:request_body) do
        { application: File.new(zip_path) }
      end

      before do
        write_random_to_file(filepath)
        `zip #{zip_path} #{filepath}`
      end

      after do
        File.unlink zip_path
        File.unlink filepath
      end

      include_examples 'when blobstore disk is full', :app_stash
    end
  end

  describe 'POST /app_stash/matches', { type: :integration, action: :upload } do
    before do
      request_body = { application: File.new(app_stash_zip_path) }
      response = make_post_request '/app_stash/entries', request_body
      expect(response.code).to eq 201
      # We had some flakes and would like to assert that the blobstore really really has these SHAs
      ['8b381f8864b572841a26266791c64ae97738a659','594eb15515c89bbfb0874aa4fd4128bee0a1d0b5'].each do |entry|
        expect(blobstore_client.key_exist?(entry)).to be_truthy
      end
    end

    subject(:response) { make_post_request '/app_stash/matches', sha_list.to_json }

    context 'when all entries match' do
      let(:sha_list) do
        [
          { 'sha1' => '8b381f8864b572841a26266791c64ae97738a659' },
          { 'sha1' => '594eb15515c89bbfb0874aa4fd4128bee0a1d0b5' }
        ]
      end

      it 'returns all given entries' do
        expect(response.code).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body).to eq(sha_list)
      end
    end

    context 'when none of entries match' do
      let(:sha_list) { [{ 'sha1' => 'abcde' }] }

      it 'returns an empty list' do
        response_body = JSON.parse(response.body)
        expect(response_body).to be_empty
      end
    end

    context 'when some of the entries matches' do
      let(:sha_list) do
        [
          { 'sha1' => '8b381f8864b572841a26266791c64ae97738a659' },
          { 'sha1' => 'abcde' }
        ]
      end

      it 'returns only the matching entries' do
        expect(response.code).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body).to eq([{ 'sha1' => '8b381f8864b572841a26266791c64ae97738a659' }])
      end
    end

    context 'when the sha list is empty' do
      let(:sha_list) { [] }

      it 'returns HTTP status 422' do
        expect(response.code).to eq(422)
      end

      it 'returns an error' do
        description = JSON.parse(response.body)['description']
        expect(description).to eq('The request is semantically invalid: must be a non-empty array.')
      end
    end
  end

  describe 'POST /app_stash/bundles', { type: :integration, action: :upload } do
    before do
      request_body = { application: File.new(app_stash_zip_path) }
      response = make_post_request('/app_stash/entries', request_body)
      expect(response.code).to eq(201)
      # We had some flakes and would like to assert that the blobstore really really has these SHAs
      ['8b381f8864b572841a26266791c64ae97738a659','594eb15515c89bbfb0874aa4fd4128bee0a1d0b5'].each do |entry|
        expect(blobstore_client.key_exist?(entry)).to be_truthy
      end
    end

    let(:default_file_mode) { '744' }
    let(:endpoint) { '/app_stash/bundles' }
    let(:resources) do
      [
        { 'fn' => 'app.rb', 'sha1' => '8b381f8864b572841a26266791c64ae97738a659', 'mode' => '666' },
        { 'fn' => 'lib/lib.rb', 'sha1' => '594eb15515c89bbfb0874aa4fd4128bee0a1d0b5' }
      ]
    end
    subject(:response) { make_post_request endpoint, resources.to_json }

    it 'returns HTTP status 200' do

      expect(response.code).to eq(200)
    end

    it 'returns the correct app package' do
      zip_file = File.join(Dir.mktmpdir('app-stash'), 'app.zip')
      File.open(zip_file, 'w') do |file|
        file.write(response.body)
      end

      unzip_destination = Dir.mktmpdir('app-unzip')
      `unzip -qq -:  -d #{unzip_destination} #{zip_file}`

      resources.each do |resource|
        file_path = File.join(unzip_destination, resource['fn'])
        expect(File.exist?(file_path)).to be(true)
        expect(Digest::SHA1.file(file_path).hexdigest).to eq(resource['sha1'])

        expected_file_mode = resource['mode'] ? resource['mode'] : default_file_mode
        expect(File.stat(file_path).mode.to_s(8)).to eq("100#{expected_file_mode}")
      end
    end

    context 'when requested unexistent resources' do
      let(:resources) do
        [
          { 'fn' => 'app.rb', 'sha1' => '8b381f8864b572841a26266791c64ae97738a659' },
          { 'fn' => 'lib/lib.rb', 'sha1' => 'not-there' }
        ]
      end

      it 'returns 404 and an error' do
        expect(response.code).to eq(404)
        description = JSON.parse(response.body)['description']
        expect(description).to eq('not-there not found')
      end
    end

    context 'when the request contains an entry with a missing sha1 key' do
      let(:resources) do
        [
          { 'fn' => 'app.rb', 'sha1' => '8b381f8864b572841a26266791c64ae97738a659' },
          { 'fn' => 'lib/lib.rb' }
        ]
      end

      it 'returns 422 and an error' do
        expect(response.code).to eq(422)
        description = JSON.parse(response.body)['description']
        expect(description).to eq('The request is semantically invalid: key `sha1` missing or empty')
      end
    end

    context 'when the request contains an entry with a missing fn key' do
      let(:resources) do
        [
          { 'fn' => 'app.rb', 'sha1' => '8b381f8864b572841a26266791c64ae97738a659' },
          { 'sha1' => '594eb15515c89bbfb0874aa4fd4128bee0a1d0b5' }
        ]
      end

      it 'returns 422 and an error' do
        expect(response.code).to eq(422)
        description = JSON.parse(response.body)['description']
        expect(description).to eq('The request is semantically invalid: key `fn` missing or empty')
      end
    end
  end
end
