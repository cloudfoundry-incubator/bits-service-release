require 'rspec'
require 'rspec/collection_matchers'
require 'rest-client'

require 'pry'
require 'pry-nav'

Dir[File.expand_path('support/**/*.rb', File.dirname(__FILE__))].each { |file| require file }

RSpec.configure do |conf|
  include EnvironmentHelpers
  include HttpHelpers
  include ManifestHelpers
  include BackendHelpers
  include ResponseHelpers
  include FileHelpers
end

RSpec::Matchers.define :be_a_404 do |expected|
  match do |response| # actual
    expect(response.code).to eq 404
    json = JSON.parse(response.body)
    expect(json['code']).to eq(10000)
    expect(json['description']).to match(/Unknown request/)
  end
end
