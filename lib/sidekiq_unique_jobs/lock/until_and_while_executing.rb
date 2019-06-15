# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Locks jobs while the job is executing in the server process
    # - Locks on perform_in or perform_async (see {UntilExecuting})
    # - Unlocks before yielding to the worker's perform method (see {UntilExecuting})
    # - Locks before yielding to the worker's perform method (see {WhileExecuting})
    # - Unlocks after yielding to the worker's perform method (see {WhileExecuting})
    #
    # See {#lock} for more information about the client.
    # See {#execute} for more information about the server
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class UntilAndWhileExecuting < BaseLock
      # Executes in the Sidekiq server process
      # @yield to the worker class perform method
      def execute
        if unlock
          runtime_lock.execute { return yield }
        else
          log_warn "couldn't unlock digest: #{item[UNIQUE_DIGEST]} #{item[JID]}"
        end
      end

      #
      # Lock only when the server is processing the job
      #
      #
      # @return [SidekiqUniqueJobs::Lock::WhileExecuting] an instance of a lock
      #
      def runtime_lock
        @runtime_lock ||= SidekiqUniqueJobs::Lock::WhileExecuting.new(item, callback, redis_pool)
      end
    end
  end
end
