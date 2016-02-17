require 'aws-sdk'

module Backend
  module S3
    class Client < Backend::ClientBase
      def initialize(access_key_id, secret_access_key, bucket, region=nil)
        @client = Aws::S3::Client.new(
          region: region || 'us-east-1',
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
        )
        @bucket = bucket
      end

      def guid_exist?(guid)
        path = path_for_guid(guid)
        @client.get_object(
          bucket: @bucket,
          key: path,
        )
        true
      rescue Aws::S3::Errors::NoSuchKey
        false
      end
    end
  end
end
