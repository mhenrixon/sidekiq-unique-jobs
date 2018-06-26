# frozen_string_literal: true

module SidekiqUniqueJobs
  module Unlockable
    module_function

    def unlock(item)
      SidekiqUniqueJobs::UniqueArgs.digest(item)
      SidekiqUniqueJobs::Locksmith.new(item).unlock
    end

    def delete(item)
      SidekiqUniqueJobs::UniqueArgs.digest(item)
      SidekiqUniqueJobs::Locksmith.new(item).delete!
    end
  end
end
