module SidekiqUniqueJobs
  class RunLockTimeoutCalculator
    include TimeoutCalculator

    def self.for_item(item)
      new(item)
    end

    def initialize(item)
      @item = item
    end

    def seconds
      run_lock_expiration
    end

    def run_lock_expiration
      @run_lock_expiration ||=
        (
          worker_class_run_lock_expiration ||
          SidekiqUniqueJobs.config.default_run_lock_expiration
        ).to_i
    end
  end
end
