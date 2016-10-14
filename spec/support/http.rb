module HttpHelpers
  def make_get_request(path, args={})
    try_catch { RestClient::Request.execute({ url: url(path), method: :get, verify_ssl: false, headers: {host: private_endpoint.hostname} }.merge(args)) }
  end

  def make_delete_request(path)
    try_catch { RestClient.delete url(path), host: private_endpoint.hostname }
  end

  def make_post_request(path, body)
    try_catch { RestClient.post url(path), body, host: private_endpoint.hostname }
  end

  def make_put_request(path, body)
    try_catch { RestClient.put url(path), body, host: private_endpoint.hostname }
  end

  private

  def url(path)
    "http://#{private_endpoint_ip}#{path}"
  end

  def try_catch
    yield
  rescue RestClient::Exception => e
    e.response
  end
end
