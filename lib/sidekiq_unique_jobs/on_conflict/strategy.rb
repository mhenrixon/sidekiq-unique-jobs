# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Abstract conflict strategy class
    #
    # @abstract
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Strategy
      include SidekiqUniqueJobs::Logging

      # The sidekiq job hash
      # @return [Hash] the Sidekiq job hash
      attr_reader :item

      # @param [Hash] item the Sidekiq job hash
      def initialize(item)
        @item = item
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
