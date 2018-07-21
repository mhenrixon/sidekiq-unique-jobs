# frozen_string_literal: true

module SidekiqUniqueJobs
  # Utility module to help manage unique keys in redis.
  # Useful for deleting keys that for whatever reason wasn't deleted
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Unlockable
    module_function

    # Unlocks a job.
    # @param [Hash] item a Sidekiq job hash
    def unlock(item)
      SidekiqUniqueJobs::UniqueArgs.digest(item)
      SidekiqUniqueJobs::Locksmith.new(item).unlock
    end

    # Deletes a lock regardless of if it was locked or not.
    #
    # This is good for situations when a job is locked by another item
    # @param [Hash] item a Sidekiq job hash
    def delete(item)
      SidekiqUniqueJobs::UniqueArgs.digest(item)
      SidekiqUniqueJobs::Locksmith.new(item).delete!
    end
  end
end
