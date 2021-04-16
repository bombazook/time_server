require 'rspec'
require 'simplecov'
require 'byebug'
require 'rspec-benchmark'

SimpleCov.start

require 'time_server'

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
end
