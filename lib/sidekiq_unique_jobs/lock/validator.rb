# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    #
    # Validator base class to avoid some duplication
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class Validator
      #
      # Shorthand for `new(options).validate`
      #
      # @param [Hash] options the sidekiq_options for the worker being validated
      #
      # @return [LockConfig] the lock configuration with errors if any
      #
      def self.validate(options)
        new(options).validate
      end

      #
      # @!attribute [r] lock_config
      #   @return [LockConfig] the lock configuration for this worker
      attr_reader :lock_config

      #
      # Initialize a new validator
      #
      # @param [Hash] options the sidekiq_options for the worker being validated
      #
      def initialize(options)
        @lock_config = LockConfig.new(options)
      end

      #
      # Validate the workers lock configuration
      #
      #
      # @return [LockConfig] the lock configuration with errors if any
      #
      def validate
        case lock_config.type
        when :while_executing
          validate_server
        when :until_executing
          validate_client
        else
          validate_client
          validate_server
        end

        lock_config
      end

      #
      # Validates the client configuration
      #
      def validate_client
        ClientValidator.validate(lock_config)
      end

      #
      # Validates the server configuration
      #
      def validate_server
        ServerValidator.validate(lock_config)
      end
    end
  end
end
