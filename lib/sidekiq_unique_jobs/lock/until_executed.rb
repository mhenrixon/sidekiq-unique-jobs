module SidekiqUniqueJobs
  module Lock
    class UntilExecuted
      OK ||= 'OK'.freeze

      include SidekiqUniqueJobs::Unlockable

      extend Forwardable
      def_delegators :Sidekiq, :logger

      def initialize(item, redis_pool = nil)
        @item = item
        @redis_pool = redis_pool
      end

      def execute(callback, &blk)
        operative = true
        send(:after_yield_yield, &blk)
      rescue Sidekiq::Shutdown
        operative = false
        raise
      ensure
        callback.call if operative && unlock(:server)
      end

      def unlock(scope)
        unless [:server, :api, :test].include?(scope)
          raise ArgumentError, "#{scope} middleware can't #{__method__} #{unique_key}"
        end

        unlock_by_key(unique_key, item[JID_KEY], redis_pool)
      end

      # rubocop:disable MethodLength
      def lock(scope)
        if scope.to_sym != :client
          raise ArgumentError, "#{scope} middleware can't #{__method__} #{unique_key}"
        end

        result = Scripts.call(:aquire_lock, redis_pool,
                              keys: [unique_key],
                              argv: [item[JID_KEY], max_lock_time])
        case result
        when 1
          logger.debug { "successfully locked #{unique_key} for #{max_lock_time} seconds" }
          true
        when 0
          logger.debug { "failed to aquire lock for #{unique_key}" }
          false
        else
          raise "#{__method__} returned an unexpected value (#{result})"
        end
      end
      # rubocop:enable MethodLength

      def unique_key
        @unique_key ||= UniqueArgs.digest(item)
      end

      def max_lock_time
        @max_lock_time ||= QueueLockTimeoutCalculator.for_item(item).seconds
      end

      def after_yield_yield
        yield
      end

      private

      attr_reader :item, :redis_pool
    end
  end
end
