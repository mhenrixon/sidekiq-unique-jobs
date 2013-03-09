module SidekiqUniqueJobs
  class Config
    def self.unique_prefix=(prefix)
      @unique_prefix = prefix
    end

    def self.unique_prefix
      @unique_prefix || "sidekiq_unique"
    end

    def self.unique_args_enabled=(enabled)
      @unique_args_enabled = enabled
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
  end
end
