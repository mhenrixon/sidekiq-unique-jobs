# frozen_string_literal: true

require "sidekiq"
require "sidekiq-unique-jobs"

Redis.exists_returns_integer = false

REDIS = Redis.new(url: ENV["REDIS_URL"])

Sidekiq.default_worker_options = {
  backtrace: true,
  retry: true,
}

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"], driver: :hiredis }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"], driver: :hiredis }

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  SidekiqUniqueJobs::Middleware::Server.configure(config)

  config.error_handlers << ->(ex, ctx_hash) { p ex, ctx_hash }
end

Sidekiq.logger       = Sidekiq::Logger.new($stdout)
Sidekiq.logger.level = :debug
Sidekiq.log_format = :json if Sidekiq.respond_to?(:log_format)
SidekiqUniqueJobs.configure do |config|
  config.debug_lua       = true
  config.lock_info       = true
  config.logger          = Sidekiq.logger
  config.max_history     = 10_000
  config.reaper          = :lua
  config.reaper_count    = 100
  config.reaper_interval = 10
  config.reaper_timeout  = 5
end
Dir[Rails.root.join("app", "workers", "**", "*.rb")].sort.each { |worker| require worker }
