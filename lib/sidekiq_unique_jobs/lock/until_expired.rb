# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    #
    # UntilExpired locks until the job expires
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class UntilExpired < UntilExecuted
      #
      # Locks a sidekiq job
      #
      # @note Will call a conflict strategy if lock can't be achieved.
      #
      # @return [String, nil] the locked jid when properly locked, else nil.
      #
      # @yield to the caller when given a block
      #
      def lock
        job_id = locksmith.lock || lock_failed
        return yield job_id if job_id && block_given?

        job_id
      end

      # Executes in the Sidekiq server process
      # @yield to the worker class perform method
      def execute(&block)
        locksmith.execute(&block)
      end
    end
  end
end
