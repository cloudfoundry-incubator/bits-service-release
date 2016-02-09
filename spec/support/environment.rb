
module EnvironmentHelpers
  def bits_service_endpoint
    ENV.fetch('BITS_SERVICE_ENDPOINT').tap do |endpoint|
      return "http://#{endpoint}" unless endpoint.start_with?('http')
    end
  end
end
