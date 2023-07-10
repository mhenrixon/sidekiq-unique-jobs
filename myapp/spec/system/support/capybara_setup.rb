# frozen_string_literal: true

require "capybara/rspec"
# require_relative "cuprite_setup"
require_relative "playwright_setup"

Capybara.server = :puma, { Silent: true }

# capybara_host = IPSocket.getaddress(Socket.gethostname)
capybara_host = "localhost"
capybara_port = ENV["TEST_PORT"].to_i + ENV["TEST_ENV_NUMBER"].to_i

# Capybara.app_host    = "http://#{capybara_host}:#{capybara_port}"
# Capybara.asset_host  = Capybara.app_host
Capybara.server              = :puma, { Silent: true }
Capybara.server_host         = capybara_host
Capybara.server_port         = capybara_port
Capybara.always_include_port = true
Capybara.raise_server_errors = true

Capybara.default_normalize_ws = true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by(:playwright, screen_size: [2048, 1536], options: { js_errors: true })

    Capybara.page.current_window.resize_to(2048, 1536)
  end
end
