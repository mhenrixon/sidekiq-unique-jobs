# frozen_string_literal: true

module SidekiqUniqueJobs
  # Utility class to append uniqueness to the sidekiq job hash
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Job
    extend self

    # Adds timeout, expiration, unique_args, unique_prefix and unique_digest to the sidekiq job hash
    # @return [Hash] the job hash
    def prepare(item)
      add_lock_timeout(item)
      add_lock_ttl(item)
      add_digest(item)

      item
    end

    # Adds unique_args, unique_prefix and unique_digest to the sidekiq job hash
    # @return [Hash] the job hash
    def add_digest(item)
      add_unique_prefix(item)
      add_unique_args(item)
      add_unique_digest(item)

      item
    end

    private

    def add_lock_ttl(item)
      item[LOCK_TTL] = SidekiqUniqueJobs::LockTTL.calculate(item)
    end

    def add_lock_timeout(item)
      item[LOCK_TIMEOUT] = SidekiqUniqueJobs::LockTimeout.calculate(item)
    end

    def add_unique_args(item)
      item[UNIQUE_ARGS] = SidekiqUniqueJobs::LockArgs.call(item)
    end

    def add_unique_digest(item)
      item[UNIQUE_DIGEST] = SidekiqUniqueJobs::LockDigest.call(item)
    end

    def add_unique_prefix(item)
      item[UNIQUE_PREFIX] = SidekiqUniqueJobs.config.unique_prefix
    end
  end
end
