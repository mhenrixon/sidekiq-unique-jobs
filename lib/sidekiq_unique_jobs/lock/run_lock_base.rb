# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class RunLockBase
      include SidekiqUniqueJobs::Lock::PreparesItems

      def initialize(item, redis_pool = nil)
        @calculator = Timeout::RunLock.new(item)
        @item       = prepare_item(item, @calculator)
        @redis_pool = redis_pool
        @lock       = SidekiqUniqueJobs::SimpleLock.new(@item)
      end

      def lock(_scope)
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      def execute(_callback = nil)
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      def unlock(_scope)
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      private

      def fail_with_lock_timeout!
        return if @calculator.lock_timeout.to_i <= 0

        raise(SidekiqUniqueJobs::LockTimeout,
              "couldn't achieve lock for #{@lock.available_key} within: #{@calculator.lock_timeout} seconds")
      end
    end
  end
end
