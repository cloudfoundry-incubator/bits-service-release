#!/usr/bin/env ruby

require 'fog'

s = Fog::Storage.new(
  :provider => 'OpenStack',
  :openstack_auth_url => ENV.fetch('OPENSTACK_AUTH_URL'),
  :openstack_username => ENV.fetch('OPENSTACK_USER_NAME'),
  :openstack_api_key  => ENV.fetch('OPENSTACK_API_KEY'),
)

files = Pathname.glob(ENV.fetch('FILE_GLOB'))

if 1 != files.size
  warn "Expect only one FILE_GLOB, but got #{files.size}: #{files}"
  exit 1
end

file = files.first
file_name = file.basename

dir = s.directories.create key: ENV.fetch('REMOTE_FOLDER'), public: true
remote_file = dir.files.create key: file_name.to_s, body: file.open, public: true

puts "Successfully uploaded #{file_name} as #{remote_file.public_url}"
