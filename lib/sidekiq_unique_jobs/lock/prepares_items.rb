# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    module PreparesItems
      def prepare_item(item)
        item[LOCK_TIMEOUT_KEY] = @calculator.lock_timeout
        item[LOCK_EXPIRATION_KEY] = @calculator.lock_expiration
        SidekiqUniqueJobs::UniqueArgs.digest(item)
        item
      end
    end
  end
end
