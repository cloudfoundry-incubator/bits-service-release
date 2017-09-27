require 'yaml'

module ManifestHelpers
  def manifest
    @manifest ||= YAML.load_file(ENV.fetch('BITS_SERVICE_MANIFEST'))
  end

  def bits_service_config
    if manifest['properties'] && manifest['properties']['bits-service']
      manifest['properties']['bits-service']
    else
      if manifest['instance_groups'].find { |e| e['name'] == 'bits-service' }
        manifest['instance_groups'].find { |e| e['name'] == 'bits-service' }['jobs'].find { |e| e['name'] == 'bits-service' }['properties']['bits-service']
      else
        manifest['instance_groups'].find { |e| e['name'] == 'api' }['jobs'].find { |e| e['name'] == 'bits-service' }['properties']['bits-service']
      end
    end
  end

  def fog_config(resource_type)
    bits_service_config[resource_type.to_s]['fog_connection']
  end

  def webdav_config(resource_type)
    bits_service_config[resource_type.to_s]['webdav_config']
  end

  def blobstore_type(resource_type)
    bits_service_config[resource_type.to_s]['blobstore_type']
  end

  def directory_key(resource_type)
    bits_service_config[resource_type.to_s]['directory_key']
  end

  def public_endpoint
    URI(bits_service_config['public_endpoint'])
  end

  def private_endpoint
    URI(bits_service_config['private_endpoint'])
  end

  def signing_user
    bits_service_config['signing_users'][0]
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

  def cc_updates_enabled?
    cc_updates = bits_service_config['cc_updates']
    !cc_updates.nil? &&
    !cc_updates['ca_cert'].to_s.empty? &&
    !cc_updates['client_cert'].to_s.empty? &&
    !cc_updates['client_key'].to_s.empty?
  end

  def test_properties
    manifest['properties']['bits_service_tests']
  end

  def cc_api_url
    cc_config('CC_API')
  end

  def cc_user
    cc_config('CC_USER')
  end

  def cc_password
    cc_config('CC_PASSWORD')
  end

  private

  def cc_config(name)
    ENV.fetch(name)
  rescue KeyError
    raise "Bits-service test environment variable is missing: #{name}"
  end
end
