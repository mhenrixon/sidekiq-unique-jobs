# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class WhileExecuting < BaseLock
      def initialize(item, redis_pool = nil)
        super
        digest = @item[UNIQUE_DIGEST_KEY]
        @item[UNIQUE_DIGEST_KEY] = "#{digest}:RUN" unless digest.end_with?(':RUN')
      end

      def lock
        true
      end

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
