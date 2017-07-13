require 'net/ssh'

module RemoteCommands
  def remote_path_exists?(ip, path, user='vcap', password='c1oudc0w')
    Net::SFTP.start(ip, user, password: password) do |sftp|
      sftp.stat(path) do |response|
        return true if response.ok?
      end
    end

    false
  end

  def fill_storage(size='50G')
    # 6K (6 * 1024) of 1M (1024 * 1024) bytes blocks is a 6Gb file. dd will stop when it runs out of space.
    # exec_remote_cmd "dd if=/dev/zero of=#{@root_path}/dummyblob bs=1M count=#{size}"
    output = exec_remote_cmd "fallocate -l #{size} #{root_path}/dummyblob"
    output.include? 'No space left on device'
  end

  def clear_storage
    exec_remote_cmd "rm #{root_path}/dummyblob"
  end

  def delete_resource(guid)
    guid, _ = guid.split('/') if guid.include?('/')
    res = exec_remote_cmd "rm -r #{resource_root_path}/#{path_for_guid guid}"
    !res.include? 'cannot remove'
  end

  private

  def exec_remote_cmd(cmd, user='vcap', password='c1oudc0w')
    output = ''

    Net::SSH.start(job_ip, user, password: password) do |ssh|
      output = ssh.exec!("echo '#{password}' | sudo -S #{cmd}")
    end

    output
  end

  def resource_root_path
    "#{root_path}/#{directory_key}"
  end
end
