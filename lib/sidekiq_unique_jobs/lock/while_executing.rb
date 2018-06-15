# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class WhileExecuting < RunLockBase
      # Don't lock when client middleware runs
      #
      # @param _scope [Symbol] the scope, `:client` or `:server`
      # @return [Boolean] always returns true
      def lock(_scope)
        true
      end

      # Locks while server middleware executes the job
      #
      # @param callback [Proc] callback to call when finished
      # @return [Boolean] report success
      # @raise [SidekiqUniqueJobs::LockTimeout] when lock fails within configured timeout
      def execute(callback)
        @locksmith.lock(@item[LOCK_TIMEOUT_KEY]) do
          yield
          callback&.call
        end
      end

      # Unlock the current item
      #
      def unlock(_scope)
        @locksmith.unlock
        @locksmith.delete!
      end
    end
  end
end
