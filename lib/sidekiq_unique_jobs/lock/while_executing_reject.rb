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
      # Overridden with a forced {OnConflict::Reject} strategy
      # @return [OnConflict::Reject] a reject strategy
      def strategy
        @strategy ||= OnConflict.find_strategy(:reject).new(item)
      end
    end
  end
end
