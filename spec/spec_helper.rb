require 'rspec'
require 'rspec/collection_matchers'
require 'rest-client'
require 'pry'
require 'pry-nav'

require_relative 'support/backend'
require_relative 'support/response'
require_relative 'support/http'
require_relative 'support/file'
require_relative 'support/manifest'

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
    json = JSON.parse(response.body)
    expect(json['code']).to eq(10000)
    expect(json['description']).to match(/Unknown request/)
  end
end
