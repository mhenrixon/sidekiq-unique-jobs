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
        smembers(key)
      end

      def count
        scard(key)
      end
    end
  end
end
