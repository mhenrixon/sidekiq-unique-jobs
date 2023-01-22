# frozen_string_literal: true

BROWSERS = %i[
  chrome
  firefox
  webkit
].freeze
HEADLESS = %w[1 true].include?(ENV.fetch("HEADLESS", "true"))
BROWSER  = ENV.fetch("BROWSER", :webkit).to_sym

DRIVER_OPTS = {
  playwright_cli_executable_path: "./node_modules/.bin/playwright",
  browser_type: BROWSER,
  headless: HEADLESS,
  slowMo: 50,
}.freeze

Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(app, **DRIVER_OPTS)
end

Capybara.default_max_wait_time = 15
Capybara.default_driver        = :playwright
Capybara.javascript_driver     = :playwright
Capybara.save_path             = "tmp/capybara"
