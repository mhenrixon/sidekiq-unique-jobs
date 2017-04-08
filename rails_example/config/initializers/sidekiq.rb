Sidekiq.default_worker_options = {
  backtrace: true,
  retry: false,
}

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
  # config.error_handlers << Proc.new { |ex, context| Airbrake.notify_or_ignore(ex, parameters: context) }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end
