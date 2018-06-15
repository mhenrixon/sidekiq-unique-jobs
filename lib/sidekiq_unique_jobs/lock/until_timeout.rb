# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilTimeout < QueueLockBase
      # Lock item until it expires
      #
      # @param scope [Symbol] the scope, `:client` or `:server`
      # @return [Boolean] truthy for success
      # @raise [ArgumentError] if scope != :client
      def lock(scope)
        validate_scope!(actual_scope: scope, expected_scope: :client)

        @locksmith.lock(0)
      end

      # Lock item until it expires
      #
      # @param scope [Symbol] the scope, `:client` or `:server`
      # @return [Boolean] returns true
      # @raise [ArgumentError] if scope != :server
      def unlock(scope)
        validate_scope!(actual_scope: scope, expected_scope: :server)
        true
      end

      # Execute the block
      #
      # @param _callback [Proc] callback that will never get called
      def execute(_callback)
        yield if block_given?
      end
    end
  end
end
