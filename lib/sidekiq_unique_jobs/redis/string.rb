# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class String provides convenient access to redis strings
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class String < Entity
      def value
        redis { |conn| conn.get(key) }
      end

      def del(*)
        redis { |conn| conn.del(key) }
      end

      def count
        exist? ? 1 : 0
      end
    end
  end
end
