# frozen_string_literal: true

require 'yaml' if RUBY_VERSION.include?('2.0.0')
require 'forwardable'
require 'concurrent/mutable_struct'
require 'ostruct'

require 'sidekiq_unique_jobs/version'
require 'sidekiq_unique_jobs/constants'
require 'sidekiq_unique_jobs/logging'
require 'sidekiq_unique_jobs/sidekiq_worker_methods'
require 'sidekiq_unique_jobs/connection'
require 'sidekiq_unique_jobs/exceptions'
require 'sidekiq_unique_jobs/job'
require 'sidekiq_unique_jobs/util'
require 'sidekiq_unique_jobs/digests'
require 'sidekiq_unique_jobs/cli'
require 'sidekiq_unique_jobs/core_ext'
require 'sidekiq_unique_jobs/timeout'
require 'sidekiq_unique_jobs/scripts'
require 'sidekiq_unique_jobs/unique_args'
require 'sidekiq_unique_jobs/unlockable'
require 'sidekiq_unique_jobs/locksmith'
require 'sidekiq_unique_jobs/lock/base_lock'
require 'sidekiq_unique_jobs/lock/until_executed'
require 'sidekiq_unique_jobs/lock/until_executing'
require 'sidekiq_unique_jobs/lock/until_expired'
require 'sidekiq_unique_jobs/lock/while_executing'
require 'sidekiq_unique_jobs/lock/while_executing_reject'
require 'sidekiq_unique_jobs/lock/until_and_while_executing'
require 'sidekiq_unique_jobs/options_with_fallback'
require 'sidekiq_unique_jobs/middleware'
require 'sidekiq_unique_jobs/sidekiq_unique_ext'
require 'sidekiq_unique_jobs/on_conflict'

# Namespace for this gem
#
# Contains configuration and utility methods that belongs top level
#
# @author Mikael Henriksson <mikael@zoolutions.se>
module SidekiqUniqueJobs
  include SidekiqUniqueJobs::Connection

  module_function

  Config = Concurrent::MutableStruct.new(
    :default_lock_timeout,
    :enabled,
    :unique_prefix,
    :logger,
  )

  # The current configuration (See: {.configure} on how to configure)
  def config
    # Arguments here need to match the definition of the new class (see above)
    @config ||= Config.new(
      0,
      true,
      'uniquejobs',
      Sidekiq.logger,
    )
  end

  # The current logger
  # @return [Logger] the configured logger
  def logger
    config.logger
  end

  # Set a new logger
  # @param [Logger] other a new logger
  def logger=(other)
    config.logger = other
  end

  # Change global configuration while yielding
  # @yield control to the caller
  def use_config(tmp_config)
    fail ::ArgumentError, "#{name}.#{__method__} needs a block" unless block_given?

    old_config = config.to_h
    configure(tmp_config)
    yield
    configure(old_config)
  end

  # Configure the gem
  #
  # This is usually called once at startup of an application
  # @param [Hash] options global gem options
  # @option options [Integer] :default_lock_timeout (default is 0)
  # @option options [true,false] :enabled (default is true)
  # @option options [String] :unique_prefix (default is 'uniquejobs')
  # @option options [Logger] :logger (default is Sidekiq.logger)
  # @yield control to the caller when given block
  def configure(options = {})
    if block_given?
      yield config
    else
      options.each do |key, val|
        config.send("#{key}=", val)
      end
    end
  end

  def redis_version
    @redis_version ||= redis { |conn| conn.info('server')['redis_version'] }
  end
end
