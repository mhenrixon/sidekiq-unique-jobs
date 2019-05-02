# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Abstract conflict strategy class
    #
    # @abstract
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Strategy
      include SidekiqUniqueJobs::Logging

      # @!attribute [r] item
      #   @return [Hash] sidekiq job hash
      attr_reader :item
      # @!attribute [r] redis_pool
      #   @return [Sidekiq::RedisConnection, ConnectionPool, NilClass] the redis connection
      attr_reader :redis_pool

      # @param [Hash] item the Sidekiq job hash
      #
      # Initialize a new Strategy
      #
      # @param [Hash] item sidekiq job hash
      #
      def initialize(item, redis_pool = nil)
        @item       = item
        @redis_pool = redis_pool
      end

      # Use strategy on conflict
      # @raise [NotImplementedError] needs to be implemented in child class
      def call
        raise NotImplementedError, "needs to be implemented in child class"
      end

      def replace?
        is_a?(Replace)
      end
    end
  end
end
