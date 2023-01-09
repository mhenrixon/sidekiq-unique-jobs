# frozen_string_literal: true

require "sidekiq"
require "sidekiq-unique-jobs"

Redis.exists_returns_integer = false

REDIS = Redis.new(url: ENV.fetch("REDIS_URL", nil))

Sidekiq.default_worker_options = {
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

Sidekiq.logger       = Sidekiq::Logger.new($stdout)
Sidekiq.logger.level = :debug
Sidekiq.log_format   = :json if Sidekiq.respond_to?(:log_format)
SidekiqUniqueJobs.configure do |config|
  config.debug_lua       = false # true for debugging
  config.lock_info       = false # true for debugging
  config.max_history     = 1000  # keeps n number of changelog entries
  config.reaper          = :ruby # also :lua but that will lock while cleaning
  config.reaper_count    = 1000  # Reap maximum this many orphaned locks
  config.reaper_interval = 10    # Reap every 10 seconds
  config.reaper_timeout  = 5     # Give the reaper 5 seonds to finish
end
Dir[Rails.root.join("app", "workers", "**", "*.rb")].sort.each { |worker| require worker }
