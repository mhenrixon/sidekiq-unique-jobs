# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class Hash provides convenient access to redis hashes
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class Hash < Entity
      def entries(with_values: false)
        if with_values
          redis { |conn| conn.hgetall(key) }
        else
          redis { |conn| conn.hkeys(key) }
        end
      end

      def [](member)
        redis { |conn| conn.hget(key, member) }
      end

      def count
        redis { |conn| conn.hlen(key) }
      end
    end
  end
end
