
require 'spec_helper'

# TODO: (pego) rename properly (also this file)
describe 'bits-service' do
  context 'https' do
    it "returns a redirect (302), because for migration we don't want to break the bits-service client" do
      url = URI("#{private_endpoint}/packages/some-irrelevant-guid").tap { |uri| uri.scheme = 'http' }.to_s
      response = try_catch { RestClient::Request.execute({ url: url, method: :get, verify_ssl: false, max_redirects: 0}) }
      expect(response.code).to eq 302
    end
  end
end
