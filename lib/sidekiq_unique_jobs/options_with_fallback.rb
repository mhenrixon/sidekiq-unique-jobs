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
    def self.included(base)
      base.send(:include, SidekiqUniqueJobs::SidekiqWorkerMethods)
    end

    # A convenience method for using the configured locks
    def locks
      SidekiqUniqueJobs.locks
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
    def log_duplicate?
      options[LOG_DUPLICATE] || item[LOG_DUPLICATE]
    end

    # Check if we should log duplicate payloads
    # @return [SidekiqUniqueJobs::Lock::BaseLock] an instance of a child class
    def lock_instance
      @lock_instance ||= lock_class.new(item, after_unlock_hook, @redis_pool)
    end

    def lock_class
      @lock_class ||= begin
        locks.fetch(lock_type.to_sym) do
          raise UnknownLock, "No implementation for `lock: :#{lock_type}`"
        end
      end
    end

    # @return [Symbol]
    def lock_type
      @lock_type ||= options[LOCK] || item[LOCK] || unique_type
    end

    def unique_type
      options[UNIQUE] || item[UNIQUE]
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
