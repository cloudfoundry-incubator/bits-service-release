#!/usr/bin/env ruby

require 'erb'

manifest = ERB.new(File.read(ARGV[0]))
puts manifest.result
