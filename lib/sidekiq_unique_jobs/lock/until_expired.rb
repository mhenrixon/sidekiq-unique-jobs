# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Locks jobs until the lock has expired
    # - Locks on perform_in or perform_async
    # - Unlocks when the expiration is hit
    #
    # See {#lock} for more information about the client.
    # See {#execute} for more information about the server
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class UntilExpired < BaseLock
      # Prevents these locks from being unlocked
      # @return [true] always returns true
      def unlock
        true
      end

      # Executes in the Sidekiq server process
      # @yield to the worker class perform method
      def execute
        return unless locked?

        yield
        # this lock does not handle after_unlock since we don't know when that would happen
      end
    end
  end
end
