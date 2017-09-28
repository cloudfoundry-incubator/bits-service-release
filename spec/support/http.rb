require 'support/environment'

module HttpHelpers
  include EnvironmentHelpers

  def make_get_request(path, args={})
    puts url(path)
    try_catch {
      RestClient::Request.execute({ url: url(path), method: :get, verify_ssl: OpenSSL::SSL::VERIFY_PEER, ssl_ca_file: ca_cert }.merge(args))
    }
  end

  def make_delete_request(path)
    try_catch {
      RestClient::Request.execute({ url: url(path), method: :delete, verify_ssl: OpenSSL::SSL::VERIFY_PEER, ssl_ca_file: ca_cert })
      # RestClient.delete url(path)
    }
  end

  def make_post_request(path, body)
    # try_catch { RestClient.post url(path), body }
    try_catch {
      RestClient::Resource.new(
        url(path),
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_ca_file: ca_cert
      ).post body
    }
  end

  def make_put_request(path, body)
    try_catch {
      RestClient::Resource.new(
        url(path),
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_ca_file: ca_cert
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
