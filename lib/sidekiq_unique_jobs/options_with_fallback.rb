# frozen_string_literal: true

module SidekiqUniqueJobs
  # Shared logic for dealing with options
  # This class requires 3 things to be defined in the class including it
  #   1. item (required)
  #   2. options (can be nil)
  #   3. worker_class (required, can be anything)
  module OptionsWithFallback
    LOCKS = {
      until_and_while_executing: SidekiqUniqueJobs::Lock::UntilAndWhileExecuting,
      until_executed:            SidekiqUniqueJobs::Lock::UntilExecuted,
      until_executing:           SidekiqUniqueJobs::Lock::UntilExecuting,
      until_timeout:             SidekiqUniqueJobs::Lock::UntilTimeout,
      while_executing:           SidekiqUniqueJobs::Lock::WhileExecuting,
      while_executing_reject:    SidekiqUniqueJobs::Lock::WhileExecutingReject,
    }.freeze

    def self.included(base)
      base.send(:include, SidekiqUniqueJobs::SidekiqWorkerMethods)
    end

    def unique_enabled?
      SidekiqUniqueJobs.config.enabled && lock_type
    end

    def unique_disabled?
      !unique_enabled?
    end

    def log_duplicate_payload?
      options[LOG_DUPLICATE_KEY] || item[LOG_DUPLICATE_KEY]
    end

    def lock
      @lock ||= lock_class.new(item, @redis_pool)
    end

    def lock_class
      @lock_class ||= begin
        LOCKS.fetch(lock_type.to_sym) do
          fail UnknownLock, "No implementation for `unique: :#{lock_type}`"
        end
      end
    end

    def lock_type
      @lock_type ||= options[UNIQUE_KEY] || item[UNIQUE_KEY]
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
