# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class QueueLockBase
      include SidekiqUniqueJobs::Lock::PreparesItems

      def initialize(item, redis_pool = nil)
        @calculator = SidekiqUniqueJobs::Timeout::QueueLock.new(item)
        @item       = prepare_item(item)
        @redis_pool = redis_pool
        @lock       = SidekiqUniqueJobs::Lock.new(@item, @redis_pool)
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

      def validate_scope!(actual_scope:, expected_scope:)
        return if actual_scope == expected_scope
        raise ArgumentError, "`#{actual_scope}` client middleware can't unlock #{@item[UNIQUE_DIGEST_KEY]}"
      end
    end
  end
end
