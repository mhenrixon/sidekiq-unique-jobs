# frozen_string_literal: true

module SidekiqUniqueJobs
  # Utility class to append uniqueness to the sidekiq job hash
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Job
    extend self

    # Adds timeout, expiration, unique_args, unique_prefix and unique_digest to the sidekiq job hash
    # @return [void] nothing returned here matters
    def add_uniqueness(item)
      add_timeout_and_expiration(item)
      add_digest(item)
      item
    end

    def prepare(item)
      add_uniqueness(item)
      item
    end

    def add_digest(item)
      add_unique_prefix(item)
      add_unique_args(item)
      add_unique_digest(item)
      item
    end

    private

    def add_timeout_and_expiration(item)
      calculator = SidekiqUniqueJobs::TimeCalculator.new(item)
      item[LOCK_TIMEOUT] = calculator.lock_timeout
      item[LOCK_TTL]     = calculator.lock_ttl
    end

    def add_unique_args(item)
      item[UNIQUE_ARGS] = SidekiqUniqueJobs::UniqueArgs.call(item)
    end

    def add_unique_digest(item)
      item[UNIQUE_DIGEST] = SidekiqUniqueJobs::UniqueDigest.call(item)
    end

    def add_unique_prefix(item)
      item[UNIQUE_PREFIX] = SidekiqUniqueJobs.config.unique_prefix
    end
  end
end
