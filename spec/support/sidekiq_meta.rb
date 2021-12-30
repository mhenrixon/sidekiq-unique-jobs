# frozen_string_literal: true

require "sidekiq/testing"

def sidekiq_redis_driver
  if RUBY_ENGINE == "ruby"
    require "hiredis"
    :hiredis
  else
    :ruby
  end
end

RSpec.configure do |config|
  config.before do |example|
    redis_db = example.metadata.fetch(:redis_db, 0)
    redis_url = "redis://localhost/#{redis_db}"
    redis_options = { url: redis_url, driver: sidekiq_redis_driver }
    redis = Sidekiq::RedisConnection.create(redis_options)

    Sidekiq.configure_client do |sidekiq_config|
      sidekiq_config.redis = redis_options
    end

    Sidekiq.redis = redis
    flush_redis

    if SidekiqUniqueJobs::VersionCheck.satisfied?(Sidekiq::VERSION, "< 7.0.0")
      enable_delay = defined?(Sidekiq::Extensions) && Sidekiq::Extensions.respond_to?(:enable_delay!)
      Sidekiq::Extensions.enable_delay! if enable_delay
    end

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
