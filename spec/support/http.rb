require 'support/environment'

module HttpHelpers
  include EnvironmentHelpers

  def make_get_request(path, args={})
    try_catch {
      RestClient::Request.execute({ url: url(path), method: :get, verify_ssl: OpenSSL::SSL::VERIFY_PEER }.merge(args))
    }
  end

  def make_delete_request(path)
    try_catch {
      RestClient::Request.execute({ url: url(path), method: :delete, verify_ssl: OpenSSL::SSL::VERIFY_PEER })
    }
  end

  def make_post_request(path, body)
    try_catch {
      RestClient::Resource.new(
        url(path),
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
      ).post body
    }
  end

  def make_put_request(path, body)
    try_catch {
      RestClient::Resource.new(
        url(path),
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
      ).put body
    }
  end

  private

  def url(path)
    "#{private_endpoint}#{path}"
  end

  def try_catch
    yield
  rescue RestClient::Exception => e
    e.response
  end
end
