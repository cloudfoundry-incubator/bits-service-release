require 'support/environment'

module HttpHelpers
  include EnvironmentHelpers

  def make_get_request(path, args={})
    try_catch { RestClient::Request.execute({ url: url(path), method: :get, verify_ssl: false }.merge(args)) }
  end

  def make_delete_request(path)
    try_catch { RestClient.delete url(path) }
  end

  def make_post_request(path, body)
    try_catch { RestClient.post url(path), body }
  end

  def make_put_request(path, body)
    try_catch { RestClient.put url(path), body }
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
