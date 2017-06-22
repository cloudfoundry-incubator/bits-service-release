require 'aws-sdk'

module Backend
  module S3
    class Client < Backend::ClientBase
      def initialize(access_key_id, secret_access_key, bucket, path_prefix, region=nil)
        @client = Aws::S3::Client.new(
          region: region || 'us-east-1',
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
        )
        @bucket = bucket
        @path_prefix = path_prefix
      end

      def key_exist?(guid)
        @client.get_object(
          bucket: @bucket,
          key: path_for_guid(guid),
        )
        true
      rescue Aws::S3::Errors::NoSuchKey
        false
      end

      def delete_resource(guid)
        resp = @client.delete_object(
          bucket: @bucket,
          key: path_for_guid(guid),
        )
        resp.successful?
      end
    end
  end
end
