# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Locks jobs until the server is done executing the job
    # - Locks on perform_in or perform_async
    # - Unlocks after yielding to the worker's perform method
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class UntilExecuted < BaseLock
      OK ||= "OK"

      # Executes in the Sidekiq server process
      # @yield to the worker class perform method
      def execute
        if locked?
          with_cleanup { yield }
        else
          log_warn "the unique_key: #{item[UNIQUE_DIGEST_KEY]} is not locked, allowing job to silently complete"
          nil
        end
      end
    end
  end
end
