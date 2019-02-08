# frozen_string_literal: true

module SidekiqUniqueJobs
  # Module containing methods shared between client and server middleware
  #
  # Requires the following methods to be defined in the including class
  #   1. item (required)
  #   2. options (can be nil)
  #   3. worker_class (required, can be anything)
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module OptionsWithFallback
    LOCKS = {
      until_and_while_executing: SidekiqUniqueJobs::Lock::UntilAndWhileExecuting,
      until_executed: SidekiqUniqueJobs::Lock::UntilExecuted,
      until_executing: SidekiqUniqueJobs::Lock::UntilExecuting,
      until_expired: SidekiqUniqueJobs::Lock::UntilExpired,
      until_timeout: SidekiqUniqueJobs::Lock::UntilExpired,
      while_executing: SidekiqUniqueJobs::Lock::WhileExecuting,
      while_executing_reject: SidekiqUniqueJobs::Lock::WhileExecutingReject,
    }.freeze

    def self.included(base)
      base.send(:include, SidekiqUniqueJobs::SidekiqWorkerMethods)
    end

    # Check if unique has been enabled
    # @return [true, false] indicate if the gem has been enabled
    def unique_enabled?
      SidekiqUniqueJobs.config.enabled && lock_type
    end

    # Check if unique has been disabled
    def unique_disabled?
      !unique_enabled?
    end

    # Check if we should log duplicate payloads
    def log_duplicate_payload?
      options[LOG_DUPLICATE_KEY] || item[LOG_DUPLICATE_KEY]
    end

    # Check if we should log duplicate payloads
    # @return [SidekiqUniqueJobs::Lock::BaseLock] an instance of a child class
    def lock
      @lock ||= lock_class.new(item, after_unlock_hook, @redis_pool)
    end

    # Check if we should log duplicate payloads
    # @return [SidekiqUniqueJobs::Lock::BaseLock] an instance of a child class
    def lock_class
      @lock_class ||= begin
        LOCKS.fetch(lock_type.to_sym) do
          raise UnknownLock, "No implementation for `lock: :#{lock_type}`"
        end
      end
    end

    # @return [Symbol]
    def lock_type
      @lock_type ||= options[LOCK_KEY] || item[LOCK_KEY] || unique_type
    end

    def unique_type
      options[UNIQUE_KEY] || item[UNIQUE_KEY]
    end

    def options
      @options ||= begin
        opts = default_worker_options.dup
        opts.merge!(worker_options) if sidekiq_worker_class?
        (opts || {}).stringify_keys
      end
    end
  end
end
