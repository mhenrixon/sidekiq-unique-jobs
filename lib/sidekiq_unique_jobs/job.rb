# frozen_string_literal: true

module SidekiqUniqueJobs
  # Utility class to append uniqueness to the sidekiq job hash
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Job
    extend self

    # Adds timeout, expiration, lock_args, lock_prefix and lock_digest to the sidekiq job hash
    # @return [Hash] the job hash
    def prepare(item)
      add_lock_timeout(item)
      add_lock_ttl(item)
      add_digest(item)
    end

    # Adds lock_args, lock_prefix and lock_digest to the sidekiq job hash
    # @return [Hash] the job hash
    def add_digest(item)
      add_lock_prefix(item)
      add_lock_args(item)
      add_lock_digest(item)

      item
    end

    private

    def add_lock_ttl(item)
      item[LOCK_TTL] = SidekiqUniqueJobs::LockTTL.calculate(item)
    end

    def add_lock_timeout(item)
      item[LOCK_TIMEOUT] = SidekiqUniqueJobs::LockTimeout.calculate(item)
    end

    def add_lock_args(item)
      item[LOCK_ARGS] = SidekiqUniqueJobs::LockArgs.call(item)
    end

    def add_lock_digest(item)
      item[LOCK_DIGEST] = SidekiqUniqueJobs::LockDigest.call(item)
    end

    def add_lock_prefix(item)
      item[LOCK_PREFIX] = SidekiqUniqueJobs.config.unique_prefix
    end
  end
end
