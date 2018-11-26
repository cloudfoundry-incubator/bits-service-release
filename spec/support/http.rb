# frozen_string_literal: true

require 'support/environment'

module HttpHelpers
  include EnvironmentHelpers

  def make_get_request(path, args={})
    try_catch {
      RestClient::Request.execute({ url: url(path), method: :get, verify_ssl: OpenSSL::SSL::VERIFY_PEER, ssl_cert_store: cert_store }.merge(args))
    }
  end

  def make_delete_request(path)
    try_catch {
      RestClient::Request.execute({ url: url(path), method: :delete, verify_ssl: OpenSSL::SSL::VERIFY_PEER, ssl_cert_store: cert_store })
    }
  end

  def make_post_request(path, body)
    try_catch {
      RestClient::Resource.new(
        url(path),
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_cert_store: cert_store
      ).post body
    }
  end

  def make_put_request(path, body)
    try_catch {
      RestClient::Resource.new(
        url(path),
        verify_ssl: OpenSSL::SSL::VERIFY_PEER,
        ssl_cert_store: cert_store
      ).put body
    }
  end

  def cert_store
    cert_store = OpenSSL::X509::Store.new
    cert_store.set_default_paths
    cert_store.add_file ca_cert
  end

  private

  def url(path)
    "#{private_endpoint}#{path}"
  end

  def try_catch
    yield
  rescue RestClient::SSLCertificateNotVerified
    raise
  rescue RestClient::Exception => e
    e.response
  end
end
