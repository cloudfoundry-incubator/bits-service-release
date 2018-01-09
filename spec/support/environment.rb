# frozen_string_literal: true

def load_private_endpoint_ip
  ENV.fetch('BITS_SERVICE_PRIVATE_ENDPOINT_IP')
rescue KeyError
  raise 'BITS_SERVICE_PRIVATE_ENDPOINT_IP not set; please set it the IP address of the bits-service job.'
end

module EnvironmentHelpers
  @@private_endpoint_ip = load_private_endpoint_ip

  def private_endpoint_ip
    @@private_endpoint_ip
  end

  def ca_cert
    ENV.fetch('BITS_SERVICE_CA_CERT')
  rescue KeyError
    raise 'BITS_SERVICE_CA_CERT not set; please set the path for the ca_cert of the bits-service job.'
  end
end
