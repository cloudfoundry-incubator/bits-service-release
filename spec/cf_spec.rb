require 'spec_helper'
require 'support/cf.rb'

describe 'CF test', if: cc_updates_enabled? do
  subject(:cf_client) do
    CFClient::Client.new(cc_api_url, cc_user, cc_password)
  end

  it 'can get a token' do
    token = cf_client.send(:fetch_token)
    expect(token).to_not be_nil
    expect(token).to_not be_empty
  end

  it 'can create an org' do
    begin
      org_id = cf_client.create_org
      expect(org_id).to_not be_empty
      space_id = cf_client.create_space(org_id)
      expect(space_id).to_not be_empty
      app_id = cf_client.create_app(space_id)
      expect(app_id).to_not be_empty
      package_id = cf_client.create_package(app_id)
      expect(package_id).to_not be_empty
    ensure
      cf_client.delete_org(org_id)
    end
    expect(cf_client.get_org(org_id)['error_code']).to eq('CF-OrganizationNotFound')
  end
end
