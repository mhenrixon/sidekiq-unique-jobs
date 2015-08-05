module SidekiqUniqueJobs
  class Config < OpenStruct
    CONFIG_ACCESSORS = [
      :unique_prefix,
      :unique_args_enabled,
      :default_expiration,
      :default_unlock_order,
      :unique_storage_method,
      :redis_mode,
      :default_run_lock,
      :default_run_lock_retry_interval,
      :default_run_lock_retries,
      :default_reschedule_on_lock_fail,
      :default_run_lock_expire
    ]

    class << self
      CONFIG_ACCESSORS.each do |method|
        define_method(method) do
          warn("#{method} has been deprecated. See readme for information")
          config.send(method)
        end

        define_method("#{method}=") do |obj|
          warn("#{method} has been deprecated. See readme for information")
          config.send("#{method}=", obj)
        end
      end

      def unique_args_enabled?
        warn('unique_args_enabled has been deprecated. See readme for information')
        config.unique_args_enabled
      end

      def config
        SidekiqUniqueJobs.config
      end
    end

    def inline_testing_enabled?
      testing_enabled? && Sidekiq::Testing.inline?
    end

    def mocking?
      inline_testing_enabled? && redis_test_mode.to_sym == :mock
    end

    def testing_enabled?
      Sidekiq.const_defined?('Testing') && Sidekiq::Testing.enabled?
    end

    def unique_args_enabled?
      config.unique_args_enabled
    end
  end
end
