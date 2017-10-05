module EnvironmentHelpers
  def private_endpoint_ip
    ENV.fetch('BITS_SERVICE_PRIVATE_ENDPOINT_IP')
  rescue KeyError
    raise 'BITS_SERVICE_PRIVATE_ENDPOINT_IP not set; please set it the IP address of the bits-service job.'
  end
end
