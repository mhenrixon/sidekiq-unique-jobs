# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class WhileExecuting < BaseLock
      def initialize(item, redis_pool = nil)
        super
        @item[UNIQUE_DIGEST_KEY] = "#{@item[UNIQUE_DIGEST_KEY]}:RUN"
      end

      def lock
        true
      end

      # TODO: Make the key for these specific to runlocks
      def execute(callback)
        @locksmith.lock(@item[LOCK_TIMEOUT_KEY]) do
          yield if block_given?
          callback&.call
        end
      end

      def unlock
        true
      end
    end
  end
end
