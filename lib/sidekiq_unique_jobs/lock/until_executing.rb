module SidekiqUniqueJobs
  module Lock
    class UntilExecuting < UntilExecuted
      def execute(after_unlock_hook, &block)
        after_unlock_hook.call if unlock(:server)
        yield
      end
    end
  end
end
