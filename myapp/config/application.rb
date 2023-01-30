# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module MyApp
  class Application < Rails::Application
    config.load_defaults 7.0

    config.time_zone = "Europe/Berlin"
    config.active_job.queue_adapter = :sidekiq

    # config.eager_load_paths << Rails.root.join("extras")

    config.generators do |g|
      g.test_framework :rspec,
                       fixtures: false,
                       view_specs: false,
                       helper_specs: true,
                       routing_specs: false,
                       request_specs: false,
                       controller_specs: false,
                       system_specs: true

      g.scaffold_stylesheet false
      g.stylesheets false
      g.helper false
      g.assets false

      g.factory_bot dir: config.root.join("spec/factories").to_s
    end
  end
end
