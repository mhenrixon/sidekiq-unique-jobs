# frozen_string_literal: true

# Easiest way to run Sidekiq::Web.
# Run with "bundle exec rackup simple.ru"

require "sidekiq"

# A Web process always runs as client, no need to configure server
Sidekiq.configure_client do |config|
  config.redis = { url: "redis://localhost:6379/0", driver: :hiredis, size: 1 }
end

require "sidekiq/web"
run Sidekiq::Web
