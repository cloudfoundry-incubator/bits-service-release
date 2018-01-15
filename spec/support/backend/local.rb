# frozen_string_literal: true

require 'net/sftp'

require_relative './remote_commands'

module Backend
  module Local
    class Client < Backend::ClientBase
      include RemoteCommands

      def initialize(root_path, directory_key, path_prefix, job_ip)
        fail 'BOSH_CLIENT env var not set' if ENV['BOSH_CLIENT'].nil?
        fail 'BOSH_CLIENT_SECRET env var not set' if ENV['BOSH_CLIENT_SECRET'].nil?
        fail 'BOSH_DEPLOYMENT env var not set' if ENV['BOSH_DEPLOYMENT'].nil?
        fail 'BOSH_ENVIRONMENT env var not set' if ENV['BOSH_ENVIRONMENT'].nil?

        @root_path = root_path
        @directory_key = directory_key
        @path_prefix = path_prefix
        raise 'job_ip must not be a http(s) endpoint' if job_ip.start_with?('http')
        @job_ip = job_ip
        @instance_name = 'bits-service'
      end

      def key_exist?(guid)
        path = File.join(root_path, directory_key, path_for_guid(guid))
        remote_path_exists?(job_ip, path)
      end

      private

      attr_reader :root_path, :directory_key, :job_ip, :instance_name
    end
  end
end
