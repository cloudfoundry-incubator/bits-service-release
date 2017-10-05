require 'spec_helper'
require 'support/cf.rb'

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
    response = RestClient::Request.execute({
      url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/#{path}",
      method: :delete,
      verify_ssl: OpenSSL::SSL::VERIFY_PEER,
      ssl_ca_file: ca_cert
      })
    expect(response.code).to be_between(200, 204)
  end

  context 'method: PUT', action: :upload do
    it 'return a signed URL that can be used to upload a package' do
      response = RestClient::Request.execute({
        url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{path}?verb=put",
        method: :get,
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_ca_file: ca_cert
        })
      signed_put_url = response.body.to_s
      RestClient::Resource.new(
        signed_put_url,
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_ca_file: ca_cert
      ).put({ package: File.new(File.expand_path('../assets/empty.zip', __FILE__)) })
      expect(response.code).to be_between(200, 201)

      response = RestClient::Request.execute({
        url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{path}",
        method: :get,
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_ca_file: ca_cert
        })
      signed_get_url = response.body.to_s

      response = RestClient::Request.execute({
        url: signed_get_url,
        method: :get,
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_ca_file: signed_get_url.to_s.include?(public_endpoint.to_s) ? ca_cert : nil
      })
      expect(response.code).to eq 200
    end
  end

  context 'method: GET', action: :upload do
    before do
      # TODO: (pego) Why does this work without authentication?
      RestClient::Resource.new(
        "#{private_endpoint}#{path}",
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_ca_file: ca_cert
      ).put({ package: File.new(File.expand_path('../assets/empty.zip', __FILE__)) })
    end

    describe '/sign' do
      it 'returns a signed URL' do
        response = RestClient::Request.execute({
          url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{path}",
          method: :get,
          verify_ssl: OpenSSL::SSL::VERIFY_PEER,
          ssl_ca_file: ca_cert
          })

        expect(response.code).to eq 200

        signed_url = response.body.to_s
        expect(signed_url).to match(/.*md5=.*/).or match(/X-Amz-Signature=/)
        expect(signed_url).to match(/.*expires=.*/).or match(/X-Amz-Expires=/)
      end

      context 'when the signing credentials are incorrect' do
        it 'returns HTTP status code 401' do
          expect {
            RestClient::Request.execute({
              url: "https://#{signing_username}:WRONG_PASSWORD@#{private_endpoint.hostname}/sign#{path}",
              method: :get,
              verify_ssl: OpenSSL::SSL::VERIFY_PEER,
              ssl_ca_file: ca_cert
              })
          }.to raise_error RestClient::Unauthorized
        end
      end
    end

    describe '/signed' do
      context 'when the signature is valid' do
        it 'resolves the signed_url and handles the request' do
          signed_url = RestClient::Request.execute({
            url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}/sign#{path}",
            method: :get,
            verify_ssl: OpenSSL::SSL::VERIFY_PEER,
            ssl_ca_file: ca_cert
            })
          response = RestClient::Request.execute({
            url: signed_url,
            method: :get,
            verify_ssl: OpenSSL::SSL::VERIFY_PEER,
            ssl_ca_file: signed_url.to_s.include?(public_endpoint.to_s) ? ca_cert : nil
          })

          expect(response.code).to eq 200
        end
      end

      context 'when the signature is invaid' do
        it 'returns a 403' do
          expect {
            RestClient::Request.execute({
              url: "#{public_endpoint}/signed#{path}?md5=INVALID_SIGNATURE&expires=1467828099",
              method: :get,
              verify_ssl: OpenSSL::SSL::VERIFY_PEER,
              ssl_ca_file: ca_cert
              })
          }.to raise_error RestClient::Forbidden
        end
      end
    end
  end
end
