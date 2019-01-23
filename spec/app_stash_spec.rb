# frozen_string_literal: true

require 'spec_helper'

require 'support/environment'
require 'support/manifest'
require 'support/s3'

RSpec.configure {
  include EnvironmentHelpers
  include ManifestHelpers
  include S3Helpers
}

describe 'app_stash endpoint' do
  after(:all) { clear_app_stash }

  let(:app_stash_zip_path) { File.expand_path('../assets/app.zip', __FILE__) }
  let(:app_stash_entries) do
    [
      { 'fn' => 'app/app.rb', 'sha1' => '8b381f8864b572841a26266791c64ae97738a659', 'mode' => '777', 'size' => 53 },
      { 'fn' => 'app/lib.rb', 'sha1' => '594eb15515c89bbfb0874aa4fd4128bee0a1d0b5', 'mode' => '666', 'size' => 36 }
    ]
  end

  describe 'POST /app_stash/entries', { type: :integration, action: :upload } do
    let(:endpoint) { '/app_stash/entries' }
    let(:request_body) { { application: File.new(app_stash_zip_path) } }

    it 'returns HTTP status 201 and returns a json with the receipt of the stored zip' do
      response = make_post_request endpoint, request_body

      expect(response.code).to eq 201
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
  end

  describe 'POST /app_stash/matches', { type: :integration, action: :upload } do
    before do
      request_body = { application: File.new(app_stash_zip_path) }
      response = make_post_request '/app_stash/entries', request_body
      expect(response.code).to eq 201
    end

    subject(:response) { make_post_request '/app_stash/matches', sha_list.to_json }

    context 'when all entries match' do
      let(:sha_list) do
        [
          {
            'sha1' => '8b381f8864b572841a26266791c64ae97738a659',
            'fn' => 'bla',
            'mode' => 'bla',
            'size' => 123 * 1024
          },
          {
            'sha1' => '594eb15515c89bbfb0874aa4fd4128bee0a1d0b5',
            'fn' => 'bla',
            'mode' => 'bla',
            'size' => 123 * 1024
          }
        ]
      end

      it 'returns all given entries' do
        expect(response.code).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body).to eq(sha_list)
      end
    end

    context 'when none of entries match' do
      let(:sha_list) { [{ 'sha1' => 'abcde', 'fn' => 'some-other-file', 'size' => 5, 'mode' => '777' }] }

      it 'returns an empty list' do
        response_body = JSON.parse(response.body)
        expect(response_body).to be_empty
      end
    end

    context 'when some of the entries matches' do
      let(:sha_list) do
        [
          { 'sha1' => '8b381f8864b572841a26266791c64ae97738a659', 'fn' => 'some-file', 'size' => 3 * 1024 * 1024, 'mode' => '666' },
          { 'sha1' => 'abcde', 'fn' => 'some-other-file', 'size' => 5, 'mode' => '777' }
        ]
      end

      it 'returns only the matching entries' do
        expect(response.code).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body).to eq([sha_list[0]])
      end
    end

    context 'when the sha list is empty' do
      let(:sha_list) { [] }

      it 'returns HTTP status 422 and error message ' do
        expect(response.code).to eq(422)
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
