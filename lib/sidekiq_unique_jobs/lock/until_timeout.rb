module SidekiqUniqueJobs
  module Lock
    class UntilTimeout < UntilExecuted
      def unlock(scope)
        return true if scope.to_sym == :server
        fail ArgumentError, "#{scope} middleware can't #{__method__} #{unique_key}"
      end
    end
  end
end
