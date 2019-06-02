# frozen_string_literal: true

require Rails.root.join("lib", "lock_simulator")

Sidekiq.default_worker_options = {
  backtrace: true,
  retry: false,
}

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'], driver: :hiredis }
  config.error_handlers << Proc.new {|ex,ctx_hash| p ex, ctx_hash }

  config.death_handlers << ->(job, _ex) do
    SidekiqUniqueJobs::Digests.del(digest: job['unique_digest']) if job['unique_digest']
  end

  # # accepts :expiration (optional)
  # Sidekiq::Status.configure_server_middleware config, expiration: 30.minutes

  # # accepts :expiration (optional)
  # Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes

  # schedule_file = "config/schedule.yml"

  # if File.exist?(schedule_file)
  #   Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  # end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'], driver: :hiredis }
  # accepts :expiration (optional)
  # Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes
end

Sidekiq.logger       = Sidekiq::Logger.new(STDOUT)
Sidekiq.logger.level = Logger::DEBUG
Sidekiq.log_format = :json if Sidekiq.respond_to?(:log_format)
SidekiqUniqueJobs.configure do |config|
  config.debug_lua       = true
  config.lock_info       = true
  config.max_history     = 10_000
  config.reaper          = :lua
  config.reaper_count    = 100
  config.reaper_interval = 10
  config.reaper_timeout  = 2
end
Dir[Rails.root.join("app", "workers", "**", "*.rb")].each { |worker| require worker }
