# frozen_string_literal: true
require 'sidekiq/testing'

require_relative 'version_check'

RSpec.configure do |config| # rubocop:disable Metrics/BlockLength
  config.before(:each, redis: :mock_redis) do
    require 'mock_redis'
    mock_redis = MockRedis.new
    SidekiqUniqueJobs.configure do |unique|
      unique.redis_test_mode = :mock
    end
    allow(SidekiqUniqueJobs).to receive(:mocked?).and_return(true)
    allow(SidekiqUniqueJobs).to receive(:redis_version).and_return('0.0')
    Sidekiq::Worker.clear_all

    allow(Sidekiq).to receive(:redis).and_yield(mock_redis)
  end

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
      check = VersionCheck.new(Sidekiq::VERSION, sidekiq_ver)
      check.invalid? do |operator_1, version_1, operator_2, version_2|
        skip("Sidekiq (#{Sidekiq::VERSION}) should be #{operator_1} #{version_1} AND #{operator_2} #{version_2}")
      end
    end
  end

  config.after(:each, redis: :redis) do |_example|
    Sidekiq.redis(&:flushdb)
  end
end
