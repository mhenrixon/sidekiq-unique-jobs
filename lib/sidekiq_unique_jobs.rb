# frozen_string_literal: true

require 'yaml' if RUBY_VERSION.include?('2.0.0')
require 'forwardable'
require 'concurrent/mutable_struct'
require 'ostruct'

require 'sidekiq_unique_jobs/version'
require 'sidekiq_unique_jobs/constants'
require 'sidekiq_unique_jobs/exceptions'
require 'sidekiq_unique_jobs/util'
require 'sidekiq_unique_jobs/cli'
require 'sidekiq_unique_jobs/core_ext'
require 'sidekiq_unique_jobs/timeout'
require 'sidekiq_unique_jobs/scripts'
require 'sidekiq_unique_jobs/unique_args'
require 'sidekiq_unique_jobs/unlockable'
require 'sidekiq_unique_jobs/locksmith'
require 'sidekiq_unique_jobs/options_with_fallback'
require 'sidekiq_unique_jobs/middleware'
require 'sidekiq_unique_jobs/sidekiq_unique_ext'

module SidekiqUniqueJobs
  module_function

  Concurrent::MutableStruct.new(
    'Config',
    :default_lock_timeout,
    :default_lock,
    :enabled,
    :raise_unique_args_errors,
    :unique_prefix,
  )

  def config
    # Arguments here need to match the definition of the new class (see above)
    @config ||= Concurrent::MutableStruct::Config.new(
      0,
      :while_executing,
      true,
      false,
      'uniquejobs',
    )
  end

  def default_lock
    config.default_lock
  end

  def logger
    Sidekiq.logger
  end

  def use_config(tmp_config)
    fail ::ArgumentError, "#{name}.#{__method__} needs a block" unless block_given?

    old_config = config.to_h
    configure(tmp_config)
    yield
    configure(old_config)
  end

  def configure(options = {})
    if block_given?
      yield config
    else
      options.each do |key, val|
        config.send("#{key}=", val)
      end
    end
  end

  # Attempt to constantize a string worker_class argument, always
  # failing back to the original argument when the constant can't be found
  #
  # raises an error for other errors
  def worker_class_constantize(worker_class)
    return worker_class unless worker_class.is_a?(String)
    Object.const_get(worker_class)
  rescue NameError => ex
    case ex.message
    when /uninitialized constant/
      worker_class
    else
      raise
    end
  end

  def redis_version
    @redis_version ||= connection { |conn| conn.info('server')['redis_version'] }
  end

  def connection(redis_pool = nil)
    if redis_pool
      redis_pool.with { |conn| yield conn }
    else
      Sidekiq.redis { |conn| yield conn }
    end
  end
end
