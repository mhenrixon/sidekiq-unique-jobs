# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilAndWhileExecuting < QueueLockBase
      # Lock item until the server processing starts
      #
      # @param scope [Symbol] the scope, `:client` or `:server`
      # @return [Boolean] truthy for success
      # @raise [ArgumentError] if scope != :client
      def lock(scope)
        validate_scope!(actual_scope: scope, expected_scope: :client)

        @lock.lock(0)
      end

      # Unlocks the current job, then lock for processing
      #
      # @param callback [Proc] callback to call when finished
      # @return [Boolean] report success
      # @raise [SidekiqUniqueJobs::LockTimeout] when lock fails within configured timeout
      def execute(callback)
        unlock(:server)

        runtime_lock.execute(callback) do
          yield
        end
      end

      def unlock(scope)
        validate_scope!(actual_scope: scope, expected_scope: :server)

        @lock.unlock
      end

      def runtime_lock
        @runtime_lock ||= SidekiqUniqueJobs::Lock::WhileExecuting.new(@item, @redis_pool)
      end
    end
  end
end
