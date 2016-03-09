#!/usr/bin/env ruby

require 'fog'

s = Fog::Storage.new(
  :provider => 'OpenStack',
  :openstack_auth_url => ENV['OPENSTACK_AUTH_URL'],
  :openstack_username => ENV['OPENSTACK_USER_NAME'],
  :openstack_api_key  => ENV['OPENSTACK_API_KEY'],
)

release_files = Pathname.glob(ENV['RELEASE_FILE'])

if 1 != release_files.size
  warn "Expect only one RELEASE_FILE, but got #{release_files.size}: #{release_files}"
  exit 1
end

file = release_files.first
file_name = file.basename

dir = s.directories.create key: 'releases', public: true
remote_file = dir.files.create key: file_name.to_s, body: file.open, public: true

puts "Successfully uploaded #{file_name} as #{remote_file.public_url}"
