# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Abstract base class for locks
    #
    # @abstract
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class BaseLock
      extend Forwardable

      # includes "SidekiqUniqueJobs::Logging"
      # @!parse include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::Logging

      # includes "SidekiqUniqueJobs::Reflectable"
      # @!parse include SidekiqUniqueJobs::Reflectable
      include SidekiqUniqueJobs::Reflectable

      #
      # Validates that the sidekiq_options for the worker is valid
      #
      # @param [Hash] options the sidekiq_options given to the worker
      #
      # @return [void]
      #
      def self.validate_options(options = {})
        Validator.validate(options)
      end

      # NOTE: Mainly used for a clean testing API
      #
      def_delegators :locksmith, :locked?

      # @param [Hash] item the Sidekiq job hash
      # @param [Proc] callback the callback to use after unlock
      # @param [Sidekiq::RedisConnection, ConnectionPool] redis_pool the redis connection
      def initialize(item, callback, redis_pool = nil)
        @item       = item
        @callback   = callback
        @redis_pool = redis_pool
        @attempt    = 0
        prepare_item # Used to ease testing
        @lock_config = LockConfig.new(item)
      end

      #
      # Locks a sidekiq job
      #
      # @note Will call a conflict strategy if lock can't be achieved.
      #
      # @return [String, nil] the locked jid when properly locked, else nil.
      #
      # @yield to the caller when given a block
      #
      def lock
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      # Execute the job in the Sidekiq server processor
      # @raise [NotImplementedError] needs to be implemented in child class
      def execute
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      #
      # The lock manager/client
      #
      # @api private
      # @return [SidekiqUniqueJobs::Locksmith] the locksmith for this sidekiq job
      #
      def locksmith
        @locksmith ||= SidekiqUniqueJobs::Locksmith.new(item, redis_pool)
      end

      private

      # @!attribute [r] item
      #   @return [Hash<String, Object>] the Sidekiq job hash
      attr_reader :item
      # @!attribute [r] lock_config
      #   @return [LockConfig] a lock configuration
      attr_reader :lock_config
      # @!attribute [r] redis_pool
      #   @return [Sidekiq::RedisConnection, ConnectionPool, NilClass] the redis connection
      attr_reader :redis_pool
      # @!attribute [r] callback
      #   @return [Proc] the block to call after unlock
      attr_reader :callback
      # @!attribute [r] attempt
      #   @return [Integer] the current locking attempt
      attr_reader :attempt

      def prepare_item
        return if item.key?(LOCK_DIGEST)

        # The below should only be done to ease testing
        # in production this will be done by the middleware
        SidekiqUniqueJobs::Job.prepare(item)
      end

      #
      # Handle when lock failed
      #
      # @param [Symbol] location: :client or :server
      #
      # @return [void]
      #
      def lock_failed(origin: :client)
        reflect(:lock_failed, item)
        call_strategy(origin: origin)
        nil
      end

      def call_strategy(origin:)
        @attempt += 1

        case origin
        when :client
          client_strategy.call { lock if replace? }
        when :server
          server_strategy.call { lock if replace? }
        else
          raise SidekiqUniqueJobs::InvalidArgument,
                "either `for: :server` or `for: :client` needs to be specified"
        end
      end

      def replace?
        client_strategy.replace? && attempt < 2
      end

      def unlock_and_callback
        return callback_safely if locksmith.unlock

        reflect(:unlock_failed, item)
      end

      def callback_safely
        callback&.call
        item[JID]
      rescue StandardError
        reflect(:after_unlock_callback_failed, item)
        raise
      end

      def client_strategy
        @client_strategy ||=
          OnConflict.find_strategy(lock_config.on_client_conflict).new(item, redis_pool)
      end

      def server_strategy
        @server_strategy ||=
          OnConflict.find_strategy(lock_config.on_server_conflict).new(item, redis_pool)
      end
    end
  end
end
