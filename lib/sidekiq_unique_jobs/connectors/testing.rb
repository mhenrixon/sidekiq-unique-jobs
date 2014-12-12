module SidekiqUniqueJobs
  module Connectors
    class Testing
      def self.connection(_redis_pool = nil)
        return unless SidekiqUniqueJobs.config.testing_enabled?
        yield SidekiqUniqueJobs.redis_mock
        true
      end
    end
  end
end
