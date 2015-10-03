module SidekiqUniqueJobs
  # This class exists to be testable and the entire api should be considered private
  # rubocop:disable MethodLength
  module Lock
    class UntilExecuting < UntilExecuted
    end
  end
end
