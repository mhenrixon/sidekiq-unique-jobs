module SidekiqUniqueJobs
  class Config
    class << self
      attr_writer :unique_prefix
    end

    def self.unique_prefix
      @unique_prefix || 'sidekiq_unique'
    end

    class << self
      attr_writer :unique_args_enabled
    end

    def self.unique_args_enabled?
      @unique_args_enabled || false
    end

    def self.default_expiration=(expiration)
      @expiration = expiration
    end

    def self.default_expiration
      @expiration || 30 * 60
    end

    class << self
      attr_writer :default_unlock_order
    end

    def self.default_unlock_order
      @default_unlock_order || :after_yield
    end

    def self.testing_enabled?
      if Sidekiq.const_defined?('Testing') && Sidekiq::Testing.enabled?
        require 'sidekiq_unique_jobs/testing'
        return true
      end

      false
    end
  end
end
