require_relative './backend/client_base'
require_relative './backend/s3'
require_relative './backend/local'

module BackendHelpers
  def backend_client(resource_type)
    resource_type = resource_type.to_s

    config = fog_config(resource_type)
    directory_key = directory_key(resource_type)

    case config['provider'].downcase
    when 'aws'
      Backend::S3::Client.new(
        config['aws_access_key_id'],
        config['aws_secret_access_key'],
        directory_key,
        config['region'],
      )
    when 'local'
      Backend::Local::Client.new(
        config['local_root'],
        directory_key,
        bits_service_endpoint
      )
    else
      raise "Unknown blobstore provider: #{config['provider']}"
    end
  end


end
