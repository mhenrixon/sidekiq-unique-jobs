# frozen_string_literal: true

require "capybara/rspec"
# require_relative "cuprite_setup"
require_relative "playwright_setup"

Capybara.server = :puma, { Silent: true }

RSpec.configure do |config|
  config.before(:each, type: :system) do
    # driven_by :selenium, using: :headless_firefox, screen_size: [1400, 1400]
    driven_by(:playwright, screen_size: [2048, 1536], options: { js_errors: true })

    # capybara_host = IPSocket.getaddress(Socket.gethostname)
    capybara_host = "localhost" # if capybara_host == "::1"
    capybara_port = TEST_PORT + ENV["TEST_ENV_NUMBER"].to_i
    Capybara.app_host = "http://#{capybara_host}:#{capybara_port}"
    Capybara.asset_host = Capybara.app_host
    Capybara.server_host = capybara_host
    Capybara.server_port = capybara_port
  end
end
