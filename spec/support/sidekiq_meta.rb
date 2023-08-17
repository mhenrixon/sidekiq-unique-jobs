# frozen_string_literal: true

require "sidekiq/testing"

RSpec.configure do |config|
  config.before do |example|
    redis_db = example.metadata.fetch(:redis_db, 0)
    redis_host = ENV.fetch("REDIS_HOST", "localhost")
    redis_url = "redis://#{redis_host}/#{redis_db}"
    redis_options = { url: redis_url, driver: :ruby }
    # redis = Sidekiq::RedisConnection.create(redis_options)

    Sidekiq.configure_client do |sidekiq_config|
      sidekiq_config.redis = redis_options
    end

    # allow(Sidekiq).to receive(:redis).and_yield(redis.with)
    flush_redis

    if (sidekiq = example.metadata.fetch(:sidekiq, :disable))
      sidekiq = :fake if sidekiq == true
      Sidekiq::Testing.send("#{sidekiq}!")
    end

    if (sidekiq_ver = example.metadata[:sidekiq_ver])
      unless SidekiqUniqueJobs::VersionCheck.satisfied?(Sidekiq::VERSION, sidekiq_ver) # rubocop:disable Style/SoleNestedConditional
        skip("Sidekiq (#{Sidekiq::VERSION}) should be #{sidekiq_ver}")
      end
    end
  end

  config.after do
    flush_redis
  end
end
