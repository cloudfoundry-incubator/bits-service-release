require 'spec_helper'

# TODO: (pego) rename properly (also this file)
describe 'Bits-Release' do
  context 'HTTP Frontend' do
    context 'Max Body Size' do
      let(:tmp_dir) { Dir.mktmpdir }
      let(:filepath) { File.join(tmp_dir, 'large-file.zip') }
      let(:bits_to_upload) do
        write_to_file(filepath, size_in_bytes: 2048 * 1024 + 1024)
        File.new(filepath)
      end

      it 'limits the size of the uploaded bits' do
        # Note: this is actually an invalid request, because there is no POST for buildpacks
        # The reason this is working, is that nginx checks the body size before matching paths.
        upload_body = { buildpack: bits_to_upload }
        response = make_post_request '/buildpacks', upload_body
        expect(response.code).to eq 413
      end
    end
  end
end
