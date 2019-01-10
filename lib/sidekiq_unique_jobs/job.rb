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
      add_unique_args_and_digest(item)
    end

    private

    def add_timeout_and_expiration(item)
      calculator                = SidekiqUniqueJobs::Timeout::Calculator.new(item)
      item[LOCK_TIMEOUT_KEY]    = calculator.lock_timeout
      item[LOCK_EXPIRATION_KEY] = calculator.lock_expiration
    end

    def add_unique_args_and_digest(item)
      SidekiqUniqueJobs::UniqueArgs.digest(item)
    end
  end
end
