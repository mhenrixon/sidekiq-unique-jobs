require 'sidekiq_unique_jobs/expiring_lock/time_calculator'

module SidekiqUniqueJobs
  # This class exists to be testable and the entire api should be considered private
  class ExpiringLock
    OK ||= 'OK'.freeze
    extend Forwardable
    def_delegators :SidekiqUniqueJobs, :connection, :namespace,
                   :worker_class_constantize, :config
    def_delegators :Sidekiq, :logger

    def initialize(item, redis_pool = nil)
      @item = item
      @redis_pool = redis_pool
    end

    def release!
      result = Scripts.call(:release_lock, redis_pool,
                            keys: [unique_key],
                            argv: [item['jid'.freeze]])
      case result
      when 1 # successfully deleted 1 expiring key
        logger.debug { "successfully released expiring lock for #{unique_key}" }
        true
      when 0
        logger.debug { "expiring lock #{unique_key} is not owned by #{item['jid'.freeze]}" }
        false
      when -1
        logger.debug { "#{unique_key} is not a known key" }
        false
      else
        fail "#{__method__} returned an unexpected value (#{result})"
      end
    end

    def aquire!
      result = Scripts.call(:aquire_lock, redis_pool,
                            keys: [unique_key],
                            argv: [item['jid'.freeze], max_lock_time])
      case result
      when 1 # successfully stored 1 expiring key
        logger.debug { "successfully successfully stored expiring key #{unique_key} for #{max_lock_time}" }
        true
      when 0
        logger.debug { "failed to aquire expiring lock for #{unique_key}" }
        false
      else
        fail "#{__method__} returned an unexpected value (#{result})"
      end
    end

    def unique_key
      @unique_key ||= UniqueArgs.digest(item)
    end

    def max_lock_time
      @max_lock_time ||= TimeCalculator.for_item(item).seconds
    end

    private

    attr_reader :item, :redis_pool
  end
end
