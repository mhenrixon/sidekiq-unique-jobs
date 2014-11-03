module SidekiqUniqueJobs
  module Connectors
    class Testing
      def self.conn(redis_pool = nil)
        return unless Config.testing_enabled?
        SidekiqUniqueJobs.redis_mock { |conn| conn }
      end
    end
  end
end
