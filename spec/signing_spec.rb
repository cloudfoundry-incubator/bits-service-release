require 'spec_helper'

describe 'URL Signing', type: :integration do
  let(:path) { "/packages/#{guid}" }
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

  after action: :upload do
    response = RestClient.delete("http://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/#{path}")
    expect(response.code).to be_between(200, 204)
  end

  context 'method: PUT', action: :upload do
    it 'return a signed URL that can be used to upload a package' do
      response = RestClient.get("http://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{path}?verb=put")
      signed_put_url = response.body.to_s

      response = RestClient.put(signed_put_url, { package: File.new(File.expand_path('../assets/empty.zip', __FILE__)) })
      expect(response.code).to be_between(200, 201)

      response = RestClient.get("http://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{path}")
      signed_get_url = response.body.to_s

      response = RestClient.get(signed_get_url)
      expect(response.code).to eq 200
    end
  end

  context 'method: GET', action: :upload do
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
          expect {
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
end
