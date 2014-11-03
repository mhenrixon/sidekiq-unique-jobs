module SidekiqUniqueJobs
  class Config < OpenStruct
    CONFIG_ACCESSORS = [
      :unique_prefix,
      :unique_args_enabled,
      :default_expiration,
      :default_unlock_order
    ]

    class << self
      warn('This method has been deprecated. See readme for information')
      CONFIG_ACCESSORS.each do |method|
        define_method(method) do
          warn('This method has been deprecated. See readme for information')
          config.send(method)
        end

        define_method("#{method}=") do |obj|
          warn('This method has been deprecated. See readme for information')
          config.send("#{method}=", obj)
        end
      end

      def unique_args_enabled?
        warn('This method has been deprecated. See readme for information')
        config.unique_args_enabled
      end

      def config
        SidekiqUniqueJobs.config
      end
    end

    def testing_enabled?
      if Sidekiq.const_defined?('Testing') && Sidekiq::Testing.enabled?
        require 'sidekiq_unique_jobs/testing'
        return true
      end

      false
    end

    def unique_args_enabled?
      config.unique_args_enabled
    end
  end
end
