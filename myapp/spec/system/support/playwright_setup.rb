# frozen_string_literal: true

require "capybara-playwright-driver"

BROWSERS = %i[
  chromium
  firefox
  webkit
].freeze
HEADLESS     = %w[1 true].include?(ENV.fetch("HEADLESS", "true"))
BROWSER      = ENV.fetch("BROWSER", :chromium).to_sym
LOCAL_ARGS   = %w[--use-gl=egl --no-sandbox --use-angle=gl].freeze
CI_ARGS      = [].freeze
BROWSER_ARGS = ENV["CI"] ? CI_ARGS : LOCAL_ARGS
DRIVER_OPTS  = {
  playwright_cli_executable_path: "./node_modules/.bin/playwright",
  browser_type: BROWSER,
  headless: HEADLESS,
  slowMo: 60,
  args: HEADLESS ? BROWSER_ARGS : [],
}.freeze

Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(app, **DRIVER_OPTS)
end

Capybara.default_max_wait_time = 15
Capybara.default_driver        = :playwright
Capybara.javascript_driver     = :playwright
Capybara.save_path             = "tmp/capybara"
