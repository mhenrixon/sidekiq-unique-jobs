# frozen_string_literal: true

Sidekiq.default_worker_options = {
  backtrace: true,
  retry: false,
}

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
  config.error_handlers << Proc.new {|ex,ctx_hash| p ex, ctx_hash }

  config.death_handlers << ->(job, _ex) do
    digest = job.dig('unique_digest')
    SidekiqUniqueJobs::Digests.delete_by_digest(digest) if digest
  end

  # accepts :expiration (optional)
  Sidekiq::Status.configure_server_middleware config, expiration: 30.minutes

  # accepts :expiration (optional)
  Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes

  schedule_file = "config/schedule.yml"

  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
  # accepts :expiration (optional)
  Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes
end

Sidekiq.log_format = :json if Sidekiq.respond_to?(:log_format)
SidekiqUniqueJobs.logger.level = Object.const_get("Logger::#{ENV.fetch('LOGLEVEL') { 'debug' }.upcase}")
