# frozen_string_literal: true

require 'net/sftp'

require_relative './remote_commands'

module Backend
  module Local
    class Client < Backend::ClientBase
      include RemoteCommands

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
    end
  end
end
