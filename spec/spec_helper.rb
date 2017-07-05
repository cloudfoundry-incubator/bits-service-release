require 'rspec'
require 'rspec/collection_matchers'
require 'rest-client'
require 'pry'
require 'pry-nav'
require 'securerandom'

require_relative 'support/backend'
require_relative 'support/response'
require_relative 'support/http'
require_relative 'support/file'
require_relative 'support/manifest'
require_relative 'support/cf.rb'

RSpec.configure do |conf|
  include HttpHelpers
  include ManifestHelpers
  include BackendHelpers
  include ResponseHelpers
  include FileHelpers

  conf.filter_run focus: true
  conf.run_all_when_everything_filtered = true
end

RSpec::Matchers.define :be_a_404 do |expected|
  match do |response| # actual
    expect(response.code).to eq 404
  end
end
