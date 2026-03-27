# frozen_string_literal: true

require "sidekiq"
require "sidekiq-unique-jobs"

Sidekiq.default_job_options = {
  backtrace: true,
  retry: true,
}

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", nil), driver: :ruby }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", nil), driver: :ruby }

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  SidekiqUniqueJobs::Server.configure(config)
end

SidekiqUniqueJobs.configure do |config|
  config.debug_lua       = false
  config.lock_info       = true
  config.max_history     = 1000
  config.reaper          = :ruby
  config.reaper_count    = 1000
  config.reaper_interval = 10
  config.reaper_timeout  = 5
end
