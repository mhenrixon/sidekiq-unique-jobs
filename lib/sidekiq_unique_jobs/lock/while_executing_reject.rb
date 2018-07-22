# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Locks jobs while executing
    #   Locks from the server process
    #   Unlocks after the server is done processing
    #
    # See {#lock} for more information about the client.
    # See {#execute} for more information about the server
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class WhileExecutingReject < WhileExecuting
      # Executes in the Sidekiq server process
      # @yield to the worker class perform method
      def execute
        return strategy.call unless locksmith.lock(item[LOCK_TIMEOUT_KEY])

        with_cleanup { yield }
      end

      # Overridden with a forced {OnConflict::Reject} strategy
      # @return [OnConflict::Reject] a reject strategy
      def strategy
        @strategy ||= OnConflict.find_strategy(:reject).new(item)
      end
    end
  end
end
