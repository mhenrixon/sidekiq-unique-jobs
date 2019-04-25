# frozen_string_literal: true

Sidekiq.default_worker_options = {
  backtrace: true,
  retry: false,
}

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
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
  config.redis = { url: ENV['REDIS_URL'] }
  # accepts :expiration (optional)
  # Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes
end

Sidekiq.logger       = Sidekiq::Logger.new(STDOUT)
Sidekiq.logger.level = Logger::INFO
Sidekiq.log_format = :json if Sidekiq.respond_to?(:log_format)

Dir[Rails.root.join("app", "workers", "**", "*.rb")].each { |worker| require worker }
