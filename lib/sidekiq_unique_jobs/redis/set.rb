# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class Set provides convenient access to redis sets
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class Set < Entity
      def entries
        redis { |conn| conn.smembers(key) }
      end

      def count
        redis { |conn| conn.scard(key) }
      end
    end
  end
end
