# frozen_string_literal: true

require 'spec_helper'
require 'support/cf.rb'
require 'support/http'

RSpec.configure {
  include HttpHelpers
}

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
      url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}:#{private_endpoint.port}#{path}",
      method: :delete,
      verify_ssl: OpenSSL::SSL::VERIFY_PEER,
      ssl_cert_store: cert_store
      })
    expect(response.code).to be_between(200, 204)
  end

  context 'app_stash, method: POST' do
    it 'return a signed URL that can be used to upload a package' do
      response = RestClient::Request.execute({
        url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}:#{private_endpoint.port}/sign/app_stash/matches?verb=post",
        method: :get,
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_cert_store: cert_store
        })
      signed_url = response.body.to_s

      response = RestClient::Resource.new(
        signed_url,
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_cert_store: cert_store
      ).post([
        {
          'sha1' => '8b381f8864b572841a26266791c64ae97738a659',
          'fn' => 'bla',
          'mode' => 'bla',
          'size' => 123 * 1024
        }
      ].to_json)

      expect(response.code).to eq(200)
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  context 'method: PUT', action: :upload do
    it 'return a signed URL that can be used to upload a package' do
      response = RestClient::Request.execute({
        url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}:#{private_endpoint.port}/sign#{path}?verb=put",
        method: :get,
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_cert_store: cert_store
        })
      signed_put_url = response.body.to_s
      RestClient::Resource.new(
        signed_put_url,
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_cert_store: cert_store
      ).put({ package: File.new(File.expand_path('../assets/empty.zip', __FILE__)) })
      expect(response.code).to be_between(200, 201)

      response = RestClient::Request.execute({
        url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}:#{private_endpoint.port}/sign#{path}",
        method: :get,
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_cert_store: cert_store
        })
      signed_get_url = response.body.to_s

      response = RestClient::Request.execute({
        url: signed_get_url,
        method: :get,
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_cert_store: cert_store
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
        ssl_cert_store: cert_store
      ).put({ package: File.new(File.expand_path('../assets/empty.zip', __FILE__)) })
    end

    describe '/sign' do
      it 'returns a signed URL' do
        response = RestClient::Request.execute({
          url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}:#{private_endpoint.port}/sign#{path}",
          method: :get,
          verify_ssl: OpenSSL::SSL::VERIFY_PEER,
          ssl_cert_store: cert_store
          })

        expect(response.code).to eq 200

        signed_url = response.body.to_s
        expect(signed_url).to match(/.*signature=.*/).or match(/X-Amz-Signature=/).or match(/.*md5=.*/)
        expect(signed_url).to match(/.*expires=.*/).or match(/X-Amz-Expires=/)
      end

      context 'when the signing credentials are incorrect' do
        it 'returns HTTP status code 401' do
          expect {
            RestClient::Request.execute({
              url: "https://#{signing_username}:WRONG_PASSWORD@#{private_endpoint.hostname}:#{private_endpoint.port}/sign#{path}",
              method: :get,
              verify_ssl: OpenSSL::SSL::VERIFY_PEER,
              ssl_cert_store: cert_store
              })
          }.to raise_error RestClient::Unauthorized
        end

        context 'when the resource for droplets is empty' do
          it 'returns HTTP status code 400' do
            expect {
              RestClient::Request.execute({
                url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}:#{private_endpoint.port}/sign/droplets/",
                method: :get,
                verify_ssl: OpenSSL::SSL::VERIFY_PEER,
                ssl_cert_store: cert_store
                })
            }.to raise_error RestClient::BadRequest
          end
        end

      end
    end

    describe '/signed' do
      context 'when the signature is valid' do
        it 'resolves the signed_url and handles the request' do
          signed_url = RestClient::Request.execute({
            url: "https://#{signing_username}:#{signing_password}@#{private_endpoint.hostname}:#{private_endpoint.port}/sign#{path}",
            method: :get,
            verify_ssl: OpenSSL::SSL::VERIFY_PEER,
            ssl_cert_store: cert_store
            })
          response = RestClient::Request.execute({
            url: signed_url,
            method: :get,
            verify_ssl: OpenSSL::SSL::VERIFY_PEER,
            ssl_cert_store: cert_store
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
              ssl_cert_store: cert_store
              })
          }.to raise_error RestClient::Forbidden
        end
      end
    end
  end
end
