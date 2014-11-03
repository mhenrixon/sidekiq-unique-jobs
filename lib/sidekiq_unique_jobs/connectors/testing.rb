module SidekiqUniqueJobs
  module Connectors
    class Testing
      def self.conn(_redis_pool = nil)
        return unless SidekiqUniqueJobs.config.testing_enabled?
        SidekiqUniqueJobs.redis_mock { |conn| conn }
      end
    end
  end
end
