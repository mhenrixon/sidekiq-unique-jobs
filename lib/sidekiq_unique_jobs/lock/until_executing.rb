# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilExecuting < QueueLockBase
      # Lock when client/middleware is running
      #
      # @param scope [Symbol] the scope, `:client` or `:server`
      # @return [Boolean] report success
      # @raise [ArgumentError] if scope != :client
      def lock(scope)
        validate_scope!(actual_scope: scope, expected_scope: :client)

        @lock.lock(0)
      end

      # Lock when server/middleware is running
      #
      # @param scope [Symbol] the scope, `:client` or `:server`
      # @return [Boolean] report success
      # @raise [ArgumentError] if scope != :server
      def unlock(scope)
        validate_scope!(actual_scope: scope, expected_scope: :server)

        @lock.unlock
      end

      # Executes the job
      #   before it gets executed we unlock it to enable other jobs with
      #   the same arguments to be scheduled.
      #
      # @param callback [Proc] callback to call when finished
      # @return [Boolean] report success
      # @raise [SidekiqUniqueJobs::LockTimeout] if we timed out when acquiring lock
      def execute(callback)
        callback.call if unlock(:server)
        yield
      end
    end
  end
end
