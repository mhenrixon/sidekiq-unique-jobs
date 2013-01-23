module SidekiqUniqueJobs
  class Config
    def self.unique_prefix=(prefix)
      @unique_prefix = prefix
    end

    def self.unique_prefix
      @unique_prefix || "sidekiq_unique"
    end
  end
end
