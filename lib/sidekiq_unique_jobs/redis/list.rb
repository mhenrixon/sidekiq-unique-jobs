# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class List provides convenient access to redis hashes
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class List < Entity
      def entries
        redis { |conn| conn.lrange(key, 0, -1) }
      end

      def count
        redis { |conn| conn.llen(key) }
      end
    end
  end
end
