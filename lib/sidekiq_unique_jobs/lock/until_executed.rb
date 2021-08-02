# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Locks jobs until the server is done executing the job
    # - Locks on perform_in or perform_async
    # - Unlocks after yielding to the worker's perform method
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class UntilExecuted < BaseLock
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
        token = locksmith.lock || lock_failed(origin: :client)
        return yield token if token && block_given?

        token
      end

      # Executes in the Sidekiq server process
      # @yield to the worker class perform method
      def execute
        locksmith.execute do
          yield
          unlock_and_callback
        end
      end
    end
  end
end
