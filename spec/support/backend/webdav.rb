require 'net/sftp'

module Backend
  module Webdav
    class Client < Backend::Local::Client
      def initialize(private_endpoint, directory_key)
        @job_ip = URI.parse(private_endpoint).host
        @directory_key = directory_key
      end

      def key_exist?(guid)
        path = File.join('/var/vcap/store/shared/', directory_key, path_for_guid(guid))

        remote_path_exists?(job_ip, path)
      end
    end
  end
end
