# frozen_string_literal: true

module SidekiqUniqueJobs
  module Unlockable
    module_function

    def unlock(item)
      SidekiqUniqueJobs::UniqueArgs.digest(item)
      lock = SidekiqUniqueJobs::Lock.new(item)
      lock.unlock
    end

    def delete!(item)
      SidekiqUniqueJobs::UniqueArgs.digest(item)
      lock = SidekiqUniqueJobs::Lock.new(item)
      lock.unlock
      lock.delete!
    end

    def logger
      SidekiqUniqueJobs.logger
    end
  end
end
