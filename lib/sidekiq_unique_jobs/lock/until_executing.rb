# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Locks jobs until {#execute} starts
    # - Locks on perform_in or perform_async
    # - Unlocks before yielding to the worker's perform method
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class UntilExecuting < BaseLock
      # Executes in the Sidekiq server process
      # @yield to the worker class perform method
      def execute
        unlock_with_callback
        yield
      end
    end
  end
end
