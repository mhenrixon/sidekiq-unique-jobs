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
        jid = @lock.lock
        if jid == @item[JID_KEY]
          callback&.call
          unlock(:server)
          yield
        else
          fail_with_lock_timeout!
        end
      end

      # Unlock the current item
      #
      def unlock(_scope)
        @lock.unlock
        @lock.delete!
      end
    end
  end
end
