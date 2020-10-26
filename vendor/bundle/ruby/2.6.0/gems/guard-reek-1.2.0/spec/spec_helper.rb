require 'rubygems'
require 'simplecov'
SimpleCov.start

ENV['RUBY_ENV'] ||= 'test'

require 'bundler/setup'

SimpleCov.start do
  add_group 'Libs', 'lib'
  add_filter '/vendor/bundle/'
end

if RUBY_PLATFORM != 'java'
  SimpleCov.minimum_coverage 98
  SimpleCov.maximum_coverage_drop 2
end

# Initialize Guard for running tests.
require 'guard'
Guard.setup(notify: false)

require 'guard/reek'

#make jruby and ruby 2.1 happy on travis
UncaughtThrowError = ArgumentError unless defined?(UncaughtThrowError)

RSpec.configure do |config|
end
