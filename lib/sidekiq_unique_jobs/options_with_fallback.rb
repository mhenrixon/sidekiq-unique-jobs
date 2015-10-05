module SidekiqUniqueJobs
  module OptionsWithFallback
    UNIQUE_KEY ||= 'unique'.freeze
    UNIQUE_LOCK_KEY ||= 'unique_lock'.freeze
    LOG_DUPLICATE_KEY ||= 'log_duplicate_payload'.freeze

    def unique_enabled?
      options[UNIQUE_KEY] || item[UNIQUE_KEY]
    end

    def unique_disabled?
      !unique_enabled?
    end

    def log_duplicate_payload?
      options[LOG_DUPLICATE_KEY] || item[LOG_DUPLICATE_KEY]
    end

    def lock
      @lock = lock_class.new(item)
    end

    def lock_class
      "SidekiqUniqueJobs::Lock::#{unique_lock.to_s.classify}".constantize
    end

    def unique_lock
      options[UNIQUE_LOCK_KEY] || item[UNIQUE_LOCK_KEY] || SidekiqUniqueJobs.default_lock
    end

    def options
      @options ||= worker_class.get_sidekiq_options if worker_class.respond_to?(:get_sidekiq_options)
      @options ||= {}
    end
  end
end
