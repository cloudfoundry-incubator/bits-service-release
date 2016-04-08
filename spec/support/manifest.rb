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
end
