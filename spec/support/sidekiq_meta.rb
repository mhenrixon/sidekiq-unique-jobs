# frozen_string_literal: true

require "sidekiq/testing"

require_relative "version_check"

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
    flush_redis
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
      check = VersionCheck.new(Sidekiq::VERSION, sidekiq_ver)
      check.invalid? do |operator1, version1, operator2, version2|
        skip("Sidekiq (#{Sidekiq::VERSION}) should be #{operator1} #{version1} AND #{operator2} #{version2}")
      end
    end
  end

  config.after(:each, redis: :redis) do |_example|
    flush_redis
  end
end
