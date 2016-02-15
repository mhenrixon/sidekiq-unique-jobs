module SidekiqUniqueJobs
  class QueueLockTimeoutCalculator
    include TimeoutCalculator

    def self.for_item(item)
      new(item)
    end

    def initialize(item)
      @item = item
    end

    def seconds
      time_until_scheduled + queue_lock_expiration
    end

    def queue_lock_expiration
      @queue_lock_expiration ||=
        (
          worker_class_queue_lock_expiration ||
          SidekiqUniqueJobs.config.default_queue_lock_expiration
        ).to_i
    end
  end
end
