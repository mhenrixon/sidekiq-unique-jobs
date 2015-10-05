require 'yaml' if RUBY_VERSION.include?('2.0.0') # rubocop:disable FileName
require 'sidekiq_unique_jobs/core_ext'
require 'sidekiq_unique_jobs/options_with_fallback'
require 'sidekiq_unique_jobs/scripts'
require 'sidekiq_unique_jobs/unique_args'
require 'sidekiq_unique_jobs/unlockable'
require 'sidekiq_unique_jobs/lock'
require 'sidekiq_unique_jobs/middleware'
require 'sidekiq_unique_jobs/version'
require 'sidekiq_unique_jobs/config'
require 'sidekiq_unique_jobs/sidekiq_unique_ext'

require 'ostruct'

module SidekiqUniqueJobs
  module_function

  def config
    @config ||= Config.new(
      unique_prefix: 'uniquejobs',
      unique_args_enabled: true,
      default_expiration: 30 * 60,
      default_lock: :while_executing,
      redis_test_mode: :redis # :mock
    )
  end

  def unique_args_enabled?
    config.unique_args_enabled
  end

  def default_lock
    config.default_lock
  end

  def configure(options = {})
    if block_given?
      yield config
    else
      options.each do |key, val|
        config[key] = val
      end
    end
  end

  def namespace
    @namespace ||= Sidekiq.redis { |c| c.respond_to?(:namespace) ? c.namespace : nil }
  end

  # Attempt to constantize a string worker_class argument, always
  # failing back to the original argument.
  def worker_class_constantize(worker_class)
    return worker_class unless worker_class.is_a?(String)
    worker_class.constantize
  rescue NameError
    worker_class
  end

  def redis_version
    @redis_version ||= Sidekiq.redis { |c| c.info('server')['redis_version'] }
  end

  def connection(redis_pool = nil, &block)
    return mock_redis if config.mocking?
    redis_pool ? redis_pool.with(&block) : Sidekiq.redis(&block)
  end

  def mock_redis
    @redis_mock ||= MockRedis.new if defined?(MockRedis)
  end

  def synchronize(item, redis_pool, &blk)
    Lock::WhileExecuting.synchronize(item, redis_pool, &blk)
  end
end
