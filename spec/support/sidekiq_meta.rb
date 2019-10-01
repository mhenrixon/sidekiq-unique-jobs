# frozen_string_literal: true

require "sidekiq/testing"

RSpec.configure do |config|
  config.before(:each, redis: :redis) do |example|
    redis_db = example.metadata.fetch(:redis_db) { 0 }
    redis_url = "redis://localhost/#{redis_db}"
    redis_options = { url: redis_url }
    redis = Sidekiq::RedisConnection.create(redis_options)

    Sidekiq.configure_client do |sidekiq_config|
      sidekiq_config.redis = redis_options
    end

    Sidekiq.redis = redis
    Sidekiq.redis(&:flushdb)
  end

  config.before do |example|
    Sidekiq::Worker.clear_all
    Sidekiq::Queues.clear_all

    enable_delay = defined?(Sidekiq::Extensions) && Sidekiq::Extensions.respond_to?(:enable_delay!)
    Sidekiq::Extensions.enable_delay! if enable_delay

    if (sidekiq = example.metadata.fetch(:sidekiq) { :disable })
      sidekiq = :fake if sidekiq == true
      Sidekiq::Testing.send("#{sidekiq}!")
    end

    if (sidekiq_ver = example.metadata[:sidekiq_ver])
      unless SidekiqUniqueJobs::VersionCheck.satisfied?(RUBY_VERSION, sidekiq_ver)
        skip("Ruby (#{Sidekiq::VERSION}) should be #{sidekiq_ver}")
      end
    end
  end

  config.after(:each, redis: :redis) do |_example|
    Sidekiq.redis(&:flushdb)
  end
end
