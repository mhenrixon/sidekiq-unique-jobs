# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class WhileExecuting < BaseLock
      def initialize(item, redis_pool = nil)
        super

        unless @item[UNIQUE_DIGEST_KEY].end_with?(':RUN')
          @item[UNIQUE_DIGEST_KEY] = "#{@item[UNIQUE_DIGEST_KEY]}:RUN"
        end
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
