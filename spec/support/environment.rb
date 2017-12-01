# frozen_string_literal: true

module EnvironmentHelpers
  def private_endpoint_ip
    ENV.fetch('BITS_SERVICE_PRIVATE_ENDPOINT_IP')
  rescue KeyError
    raise 'BITS_SERVICE_PRIVATE_ENDPOINT_IP not set; please set it the IP address of the bits-service job.'
  end

  def ca_cert
    ENV.fetch('BITS_SERVICE_CA_CERT')
  rescue KeyError
    raise 'BITS_SERVICE_CA_CERT not set; please set the path for the ca_cert of the bits-service job.'
  end
end
