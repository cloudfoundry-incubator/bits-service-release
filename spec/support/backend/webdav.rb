# frozen_string_literal: true

require 'net/sftp'

module Backend
  module Webdav
    class Client < Backend::Local::Client
      def initialize(private_endpoint, directory_key, path_prefix)
        @job_ip = URI.parse(private_endpoint).host
        @directory_key = directory_key
        @path_prefix = path_prefix
        # TODO: (ae, ns) Just for testing
        @root_path = '/var/vcap/store/shared/'
        @instance_name = 'blobstore'
      end

      def key_exist?(guid)
        path = File.join(root_path, directory_key, path_for_guid(guid))

        remote_path_exists?(job_ip, path)
      end

      private

      attr_reader :instance_name
    end
  end
end
