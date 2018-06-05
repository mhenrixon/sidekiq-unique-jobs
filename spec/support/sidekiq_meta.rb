# frozen_string_literal: true

RSpec.configure do |config| # rubocop:disable Metrics/BlockLength
  config.before(:each, redis: :mock_redis) do
    require 'mock_redis'
    @redis = MockRedis.new
    SidekiqUniqueJobs.configure do |unique|
      unique.redis_test_mode = :mock
    end
    allow(SidekiqUniqueJobs).to receive(:mocked?).and_return(true)
    allow(SidekiqUniqueJobs).to receive(:redis_version).and_return('0.0')

    allow(Sidekiq).to receive(:redis).and_yield(@redis)
  end

  config.before(:each, redis: :redis) do |example|
    redis_db = example.metadata.fetch(:redis_db) { 0 }
    redis_url = "redis://localhost/#{redis_db}"
    redis_options = { url: redis_url }
    redis = Sidekiq::RedisConnection.create(redis_options)

    Sidekiq.configure_client do |sidekiq_config|
      sidekiq_config.redis = redis_options
    end

    SidekiqUniqueJobs.configure do |unique_config|
      unique_config.redis_test_mode = :redis
    end

    Sidekiq.redis = redis
    Sidekiq.redis(&:flushdb)
  end

  config.before(:each) do |example|
    Sidekiq::Worker.clear_all
    Sidekiq::Queues.clear_all

    Sidekiq::Testing.server_middleware do |chain|
      chain.add SidekiqUniqueJobs::Server::Middleware
    end

    enable_delay = defined?(Sidekiq::Extensions) && Sidekiq::Extensions.respond_to?(:enable_delay!)
    Sidekiq::Extensions.enable_delay! if enable_delay

    if (sidekiq = example.metadata.fetch(:sidekiq) { :disable })
      sidekiq = :fake if sidekiq == true
      Sidekiq::Testing.send("#{sidekiq}!")
    end

    if (sidekiq_ver = example.metadata[:sidekiq_ver])
      VERSION_REGEX.match(sidekiq_ver.to_s) do |match|
        version  = match[:version]
        operator = match[:operator]

        raise 'Please specify how to compare the version with >= or < or =' unless operator

        unless Sidekiq::VERSION.send(operator, version)
          skip("Skipped due to version check (requirement was that sidekiq version is " \
               "#{operator} #{version}; was #{Sidekiq::VERSION})")
        end
      end
    end
  end

  config.after(:each, redis: :mock_redis) do
    SidekiqUniqueJobs.configure do |unique|
      unique.redis_test_mode = :redis
    end
  end

  config.after(:each, redis: :redis) do |example|
    Sidekiq.redis(&:flushdb)
    respond_to_middleware = defined?(Sidekiq::Testing) && Sidekiq::Testing.respond_to?(:server_middleware)
    Sidekiq::Testing.server_middleware(&:clear) if respond_to_middleware
    Sidekiq::Testing.disable! unless example.metadata[:sidekiq].nil?
  end
end
