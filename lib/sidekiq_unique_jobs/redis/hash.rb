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
          hgetall(key)
        else
          hkeys(key)
        end
      end

      def [](member)
        hget(key, member)
      end

      def count
        hlen(key)
      end
    end
  end
end
