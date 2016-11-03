require 'spec_helper'

describe 'URL Signing', type: :integration do
  let(:path) { "/packages/#{SecureRandom.uuid}" }

  context 'method: PUT' do
    let(:path) { "/packages/#{SecureRandom.uuid}" }
    xit 'return a signed URL that can be used to upload a package' do
      puts "http://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{path}"
      response = RestClient.get("http://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{path}")
      signed_url = response.body.to_s

      puts signed_url
      response = RestClient.put(signed_url, { package: File.new(File.expand_path('../assets/empty.zip', __FILE__))  })
      expect(response.code).to eq 201

      response = RestClient.get(signed_url)
      expect(response.code).to eq 200
    end
  end

  context 'method: GET' do
    before do
      # TODO: (pego) Why does this work without authentication?
      RestClient.put("#{private_endpoint}#{path}", { package: File.new(File.expand_path('../assets/empty.zip', __FILE__)) })
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
          puts signed_url
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

end
