# frozen_string_literal: true

require_relative './backend/client_base'
require_relative './backend/s3'
require_relative './backend/local'
require_relative './backend/webdav'

require_relative 'environment'

module BackendHelpers
  include EnvironmentHelpers

  def backend_client(resource_type)
    resource_type = resource_type.to_s

    if resource_type.to_sym == :buildpack_cache
      resource_type = 'droplets'
      path_prefix = 'buildpack_cache'
    end

    if resource_type.to_sym == :app_stash
      path_prefix = 'app_bits_cache'
    end

    resource_type = resource_type.to_s
    directory_key = directory_key(resource_type)

    if blobstore_type(resource_type) == 'webdav'
      config = webdav_config(resource_type)
      return Backend::Webdav::Client.new(
        config['private_endpoint'],
        directory_key,
        path_prefix
      )
    end

    config = fog_config(resource_type)

    case config['provider'].downcase
    when 'aws'
      Backend::S3::Client.new(
        config['aws_access_key_id'],
        config['aws_secret_access_key'],
        directory_key,
        path_prefix,
        config['region'],
      )
    when 'local'
      Backend::Local::Client.new(
        config['local_root'],
        directory_key,
        path_prefix,
        private_endpoint_ip
      )
    else
      raise "Unknown blobstore provider: #{config['provider']}"
    end
  end
end
