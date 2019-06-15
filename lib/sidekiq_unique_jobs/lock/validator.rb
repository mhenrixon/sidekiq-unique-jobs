# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    #
    # Validator base class to avoid some duplication
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class Validator < Validator
      #
      # Shorthand for `new(options).validate`
      #
      # @param [Hash] options the sidekiq_options for the worker being validated
      #
      # @return [void]
      #
      def self.validate(options)
        new(options).validate
      end

      #
      # @!attribute [r] config
      #   @return [LockConfig] the lock configuration for this worker
      attr_reader :config

      #
      # Initialize a new validator
      #
      # @param [Hash] options the sidekiq_options for the worker being validated
      #
      def initialize(options)
        @config = LockConfig.new(options)
      end

      #
      # Validate the workers lock configuration
      #
      #
      # @return [void]
      #
      def validate
        raise NotImplementedError, "no implementation for `validate`"
      end
    end
  end
end
