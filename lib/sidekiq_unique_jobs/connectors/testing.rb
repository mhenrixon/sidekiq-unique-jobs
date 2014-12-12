module SidekiqUniqueJobs
  module Connectors
    class Testing
      def self.connection(_redis_pool = nil, &block)
        return unless SidekiqUniqueJobs.config.testing_enabled?
        yield SidekiqUniqueJobs.redis_mock
        return true
      end
    end
  end
end
