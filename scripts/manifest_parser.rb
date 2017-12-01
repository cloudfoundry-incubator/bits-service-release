#!/usr/bin/env ruby
# frozen_string_literal: true

require 'erb'

manifest = ERB.new(File.read(ARGV[0]))
puts manifest.result
