require 'yaml'

module ManifestHelpers
  def manifest
    @manifest ||= YAML.load_file(ENV.fetch('BITS_SERVICE_MANIFEST'))
  end

  def fog_config(resource_type)
    manifest['properties']['bits-service'][resource_type.to_s]['fog_connection']
  end

  def webdav_config(resource_type)
    manifest['properties']['bits-service'][resource_type.to_s]['webdav_config']
  end

  def blobstore_type(resource_type)
    manifest['properties']['bits-service'][resource_type.to_s]['blobstore_type']
  end

  def directory_key(resource_type)
    manifest['properties']['bits-service'][resource_type.to_s]['directory_key']
  end

  def public_endpoint
    URI(manifest['properties']['bits-service']['public_endpoint'])
  end

  def private_endpoint
    URI(manifest['properties']['bits-service']['private_endpoint'])
  end

  def signing_user
    manifest['properties']['bits-service']['signing_users'][0]
  end

  def signing_username
    signing_user['username']
  end

  def signing_password
    signing_user['password']
  end

  def blobstore_provider(resource_type)
    if resource_type.to_sym == :buildpack_cache
      resource_type = 'droplets'
    end

    return 'webdav' if blobstore_type(resource_type) == 'webdav'

    config = fog_config(resource_type)
    config['provider'].downcase
  end
end
