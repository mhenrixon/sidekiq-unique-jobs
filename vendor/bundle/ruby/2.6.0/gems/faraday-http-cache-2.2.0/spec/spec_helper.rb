# frozen_string_literal: true
require 'uri'
require 'socket'

require 'faraday-http-cache'
require 'faraday_middleware'

# https://github.com/rails/rails/pull/14667
require 'active_support/per_thread_registry'
require 'active_support/cache'

require 'support/test_app'
require 'support/test_server'

server = TestServer.new

ENV['FARADAY_SERVER'] = server.endpoint
ENV['FARADAY_ADAPTER'] ||= 'net_http'

server.start

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.order = 'random'

  config.after(:suite) do
    server.stop
  end
end
