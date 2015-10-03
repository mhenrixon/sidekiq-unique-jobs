module SidekiqUniqueJobs
  # This class exists to be testable and the entire api should be considered private
  # rubocop:disable MethodLength
  module Lock
    class UntilTimeout < UntilExecuted
      def release!(scope)
        raise ArgumentError, "scope: #{scope} is not valid for #{__method__}" if scope.to_sym != :server
        return false
      end
    end
  end
end
