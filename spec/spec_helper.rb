require 'rspec'
require 'rspec/collection_matchers'
require 'rest-client'
require 'multi_json'

require 'pry'
require 'pry-nav'

Dir[File.expand_path('support/**/*.rb', File.dirname(__FILE__))].each { |file| require file }

RSpec.configure do |conf|
  include EnvironmentHelpers
  include HttpHelpers
end
