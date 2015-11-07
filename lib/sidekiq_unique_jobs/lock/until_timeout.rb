module SidekiqUniqueJobs
  module Lock
    class UntilTimeout < UntilExecuted
      def unlock(scope)
        if scope.to_sym == :server
          return true
        else
          fail ArgumentError, "#{scope} middleware can't #{__method__} #{unique_key}"
        end
      end

      def execute(_callback)
        yield if block_given?
      end
    end
  end
end
