# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class String provides convenient access to redis strings
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class String < Entity
      #
      # Returns the value of the key
      #
      #
      # @return [String]
      #
      def value
        redis { |conn| conn.get(key) }
      end

      #
      # Removes the key from redis
      #
      def del(*)
        redis { |conn| conn.del(key) }
      end

      #
      # Used only for compatibility with other keys
      #
      # @return [1] when key exists
      # @return [0] when key does not exists
      def count
        exist? ? 1 : 0
      end
    end
  end
end
