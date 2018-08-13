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
    # @author Maciej Mucha <maciej@northpass.com>
    class WhileExecutingReschedule < WhileExecuting
      # Executes in the Sidekiq server process
      # @yield to the worker class perform method
      def execute
        return strategy.call unless locksmith.lock(item[LOCK_TIMEOUT_KEY])

        with_cleanup { yield }
      end

      # Overridden with a forced {OnConflict::Reschedule} strategy
      # @return [OnConflict::Reschedule] a reschedule strategy
      def strategy
        @strategy ||= OnConflict.find_strategy(:reschedule).new(item)
      end
    end
  end
end
