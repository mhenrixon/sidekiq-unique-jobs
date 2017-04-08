module SidekiqUniqueJobs
  class Config < OpenStruct
    CONFIG_ACCESSORS = %i[
      unique_prefix
      default_queue_lock_expiration
      default_run_lock_expiration
      default_lock
      redis_mode
    ].freeze

    def inline_testing_enabled?
      testing_enabled? && Sidekiq::Testing.inline?
    end

    def mocking?
      inline_testing_enabled? && redis_test_mode.to_sym == :mock
    end

    def testing_enabled?
      Sidekiq.const_defined?(TESTING_CONSTANT, false) && Sidekiq::Testing.enabled?
    end
  end
end
