# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class Entity functions as a base class for redis types
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class Entity
      include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::Script::Caller
      include SidekiqUniqueJobs::JSON
      include SidekiqUniqueJobs::Timing

      attr_reader :key

      def initialize(key)
        @key = key
      end

      def exist?
        redis { |conn| conn.exists(key) }
      end

      def pttl
        redis { |conn| conn.pttl(key) }
      end

      def ttl
        redis { |conn| conn.ttl(key) }
      end

      def expires?
        pttl.positive? || ttl.positive?
      end

      def count
        0
      end
    end
  end
end
