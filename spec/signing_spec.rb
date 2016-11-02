require 'spec_helper'

context 'URL Signing', type: :integration do
  let(:path) { "/packages/#{SecureRandom.uuid}" }

  before do
    # TODO: (pego) Why does this work without authentication?
    RestClient.put("#{private_endpoint}#{path}", { package: File.new(File.expand_path('../assets/empty.zip', __FILE__))  })
  end

  describe '/sign' do
    it 'returns a signed URL' do
      response = RestClient.get("http://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{path}")

      expect(response.code).to eq 200

      signed_url = response.body.to_s
      expect(signed_url).to match(/.*md5=.*/).or match(/X-Amz-Signature=/)
      expect(signed_url).to match(/.*expires=.*/).or match(/X-Amz-Expires=/)
    end

    context 'when the signing credentials are incorrect' do
      it 'returns HTTP status code 401' do
        expect{
          RestClient.get("http://#{signing_username}:WRONG_PASSWORD@#{private_endpoint.hostname}/sign#{path}")
        }.to raise_error RestClient::Unauthorized
      end
    end
  end

  describe '/signed' do
    context 'when the signature is valid' do
      it 'resolves the signed_url and handles the request' do
        signed_url = RestClient.get("http://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{path}").body.to_s
        response = RestClient.get(signed_url)
        expect(response.code).to eq 200
      end
    end

    context 'when the signature is invaid' do
      it 'returns a 403' do
        expect {
          RestClient.get("#{public_endpoint}/signed#{path}?md5=INVALID_SIGNATURE&expires=1467828099")
        }.to raise_error RestClient::Forbidden
      end
    end
  end
end
