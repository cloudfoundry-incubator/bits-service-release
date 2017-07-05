require 'base64'
require 'json'

module CFClient
  class Client
    def initialize(api_url, user, pass)
      @api_url = api_url
      @user = user
      @pass = pass
    end

    def create_org
      resp = make_post_request('/v2/organizations',
        { name: random_name('testOrg') }.to_json
      )
      resp['metadata']['guid']
    end

    def delete_org(guid)
      make_delete_request("/v2/organizations/#{guid}?recursive=true")
    end

    def get_org(guid)
      make_get_request("/v2/organizations/#{guid}")
    end

    def create_space(parent_org_guid)
      resp = make_post_request('/v2/spaces',
        {
          name: random_name('testSpace'),
          organization_guid: parent_org_guid
        }.to_json
      )
      resp['metadata']['guid']
    end

    def create_app(parent_space_guid)
      resp = make_post_request('/v2/apps',
        {
          name: random_name('testApp'),
          space_guid: parent_space_guid
        }.to_json
      )
      resp['metadata']['guid']
    end

    def create_package(parent_app_guid)
      resp = make_post_request('/v3/packages',
        {
          type: 'bits',
          relationships: {
            app: {
              data: {
                guid: parent_app_guid
              }
            }
          }
        }.to_json
      )
      resp['guid']
    end

    private

    def login_url
      return @login_url if @login_url
      resp = RestClient::Request.execute({
        url: "#{@api_url}/v2/info",
        method: :get,
        headers: { accept: :json },
        verify_ssl: false
      })
      resp_hash = JSON.parse(resp)
      @login_url = resp_hash['token_endpoint']
    end

    def fetch_token
      body = "username=#{@user}&password=#{@pass}&client_id=cf&grant_type=password&response_type=token"
      resp = RestClient::Request.execute(
        method: :post,
        url: "#{login_url}/oauth/token",
        verify_ssl: false,
        user: 'cf', pass: '',
        payload: body
      )
      resp_hash = JSON.parse(resp)
      resp_hash['access_token']
    rescue RestClient::Exception => e
      e.response
    end

    def make_get_request(path)
      make_authorized_request(
        method: :get,
        url: url(path),
      )
    end

    def make_delete_request(path)
      make_authorized_request(
        method: :delete,
        url: url(path),
      )
    end

    def make_post_request(path, body)
      make_authorized_request(
        method: :post,
        url: url(path),
        payload: body,
      )
    end

    def make_authorized_request(args={})
      resp = RestClient::Request.execute({
        verify_ssl: false,
        headers: {
          'Authorization' => "Bearer #{auth_token}",
          'Content-type' => 'application/json'
          }
      }.merge(args))
      if resp.empty?
        {}
      else
        JSON.parse(resp)
      end
    rescue RestClient::Exception => e
      JSON.parse(e.response)
    rescue JSON::ParserError => e
      raise "JSON parsing failed: #{e.message}"
    end

    def url(path)
      "#{@api_url}#{path}"
    end

    def auth_token
      @auth_token ||= fetch_token
    end

    def random_name(base_name)
      suffix = (0...8).map { ('a'..'z').to_a[rand(26)] }.join
      base_name + '-' + suffix
    end
  end
end
