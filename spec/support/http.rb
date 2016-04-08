module HttpHelpers
  def make_get_request(path)
    try_catch { RestClient::Request.execute(:url => url(path), :method => :get, :verify_ssl => false) }
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
    "#{bits_service_endpoint}#{path}"
  end

  def try_catch
    yield
  rescue StandardError => e
    e.response
  end
end
