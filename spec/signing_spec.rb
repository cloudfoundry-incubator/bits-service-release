require 'spec_helper'

context 'URL Signing', type: :integration do
  let(:zip_filepath) { File.expand_path('../assets/empty.zip', __FILE__) }
  let(:zip_file) { File.new(zip_filepath) }
  let(:upload_body) { { package: zip_file } }
  let(:guid) { SecureRandom.uuid }
  let(:path) { "/packages/#{guid}" }
  let(:sign_url) { "#{private_endpoint}/sign#{path}" }

  before do
    response = make_put_request(path, upload_body)
    expect(response.code).to eq(201)
  end

  describe '/sign' do
    let(:sign_response) do
      make_get_request('', {
        method: :get,
        url: sign_url,
        user: signing_username,
        password: signing_password,
        verify_ssl: false
      })
    end

    it 'returns HTTP success' do
      expect(sign_response.code).to eq 200
    end

    it 'returns a signed URL' do
      signed_url = sign_response.body.to_s

      expect(signed_url).to match(/.*md5=.*/).or match(/X-Amz-Signature=/)
      expect(signed_url).to match(/.*expires=.*/).or match(/X-Amz-Expires=/)
    end

    context 'when the signing credentials are incorrect' do
      let(:signing_password) { 'wrong_password' }

      it 'returns HTTP status code 401' do
        expect(sign_response.code).to eq 401
      end
    end
  end

  describe '/signed' do
    context 'when the signature is valid' do
      let(:signed_url) do
        make_get_request('', {
            method: :get,
            url: sign_url,
            user: signing_username,
            password: signing_password,
            verify_ssl: false
        }).body.to_s
      end

      it 'resolves the signed_url and handles the request' do
        response = RestClient::Request.execute(
          url: signed_url,
          method: :get,
          verify_ssl: false
        )
        expect(response.code).to eq 200
      end
    end

    context 'when the signature is invaid' do
      let(:signed_url) { "#{public_endpoint}/signed#{path}?md5=Eg1N60x4bZigd_E3BjXE1Q&expires=1467828099" }

      it 'returns a 403' do
        response = make_get_request('', {
          url: signed_url,
          method: :get,
          verify_ssl: false
        })
        expect(response.code).to eq 403
      end
    end
  end
end
