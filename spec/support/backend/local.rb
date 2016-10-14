require 'net/sftp'

module Backend
  module Local
    class Client < Backend::ClientBase
      def initialize(root_path, directory_key, path_prefix, job_ip)
        @root_path = root_path
        @directory_key = directory_key
        @path_prefix = path_prefix
        raise 'job_ip must not be a http(s) endpoint' if job_ip.start_with?('http')
        @job_ip = job_ip
      end

      def key_exist?(guid)
        path = File.join(root_path, directory_key, path_for_guid(guid))

        remote_path_exists?(job_ip, path)
      end

      private

      attr_reader :root_path, :directory_key, :job_ip

      def remote_path_exists?(ip, path)
        Net::SFTP.start(ip, 'vcap', password: 'c1oudc0w') do |sftp|
          sftp.stat(path) do |response|
            return true if response.ok?
          end
        end

        false
      end
    end
  end
end
