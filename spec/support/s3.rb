# frozen_string_literal: true

module S3Helpers
  def clear_app_stash
    if blobstore_provider(:app_stash) == 'aws'
      require 'aws-sdk'
      client = Aws::S3::Client.new(
                  region: fog_config(:app_stash)['region'] || 'us-east-1',
                  access_key_id: fog_config(:app_stash)['aws_access_key_id'],
                  secret_access_key: fog_config(:app_stash)['aws_secret_access_key'],
                )
      client.list_objects(bucket: directory_key(:app_stash), prefix: "app_bits_cache").contents.each do |object|
        client.delete_object(bucket: directory_key(:app_stash), key: object.key)
      end
    end
  end
end
