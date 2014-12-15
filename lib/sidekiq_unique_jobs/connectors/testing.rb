module SidekiqUniqueJobs
  module Connectors
    class Testing
      def self.with_connection(_redis_pool = nil)
        return unless SidekiqUniqueJobs.config.testing_enabled?
        yield(SidekiqUniqueJobs.redis_mock)
      end
    end
  end
end
