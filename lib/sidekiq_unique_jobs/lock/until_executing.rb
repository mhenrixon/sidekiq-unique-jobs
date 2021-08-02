# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Locks jobs until {#execute} starts
    # - Locks on perform_in or perform_async
    # - Unlocks before yielding to the worker's perform method
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class UntilExecuting < BaseLock
      #
      # Locks a sidekiq job
      #
      # @note Will call a conflict strategy if lock can't be achieved.
      #
      # @return [String, nil] the locked jid when properly locked, else nil.
      #
      def lock
        job_id = locksmith.lock || lock_failed
        return yield job_id if job_id && block_given?

        job_id
      end

      # Executes in the Sidekiq server process
      # @yield to the worker class perform method
      def execute
        callback_safely if locksmith.unlock
        yield
      end
    end
  end
end
