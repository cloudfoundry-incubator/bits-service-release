#!/usr/bin/env ruby

require 'fog'

start_time = Time.now

puts "Started: #{start_time}"

s = Fog::Storage.new(
  provider: 'OpenStack',
  openstack_auth_url: ENV.fetch('OPENSTACK_AUTH_URL'),
  openstack_username: ENV.fetch('OPENSTACK_USER_NAME'),
  openstack_api_key: ENV.fetch('OPENSTACK_API_KEY'),
)

files = Pathname.glob(ENV.fetch('FILE_GLOB'))

if 1 != files.size
  warn "Expect only one FILE_GLOB, but got #{files.size}: #{files}"
  exit 1
end

file = files.first
file_name = file.basename

release_version_file = Pathname(ENV.fetch('VERSION_FILE'))
release_version = release_version_file.read.chomp

if release_version.empty?
  warn "Could not find a release version in #{release_version_file}"
  exit 1
end

dir = s.directories.create key: ENV.fetch('REMOTE_FOLDER'), public: true

remote_file = dir.files.create(
  key: File.join(release_version, file_name),
  body: file.open,
  public: true
)

end_time = Time.now
puts "Finished: #{end_time}"
puts "Duration: #{(end_time - start_time) / 60} minutes"
puts
puts "Successfully uploaded #{file_name} as #{remote_file.public_url}"
