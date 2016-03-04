module SidekiqUniqueJobs
  module Lock
    class WhileExecuting
      def self.synchronize(item, redis_pool = nil)
        new(item, redis_pool).synchronize { yield }
      end

      def initialize(item, redis_pool = nil)
        @item = item
        @mutex = Mutex.new
        @redis_pool = redis_pool
        @unique_digest = "#{create_digest}:run"
      end

      def synchronize
        @mutex.lock
        sleep 0.001 until locked?

        yield
      rescue Sidekiq::Shutdown
        logger.fatal { "the unique_key: #{@unique_digest} needs to be unlocked manually" }
        raise
      ensure
        SidekiqUniqueJobs.connection(@redis_pool) { |c| c.del @unique_digest }
        @mutex.unlock
      end

      def locked?
        Scripts.call(:synchronize, @redis_pool,
                     keys: [@unique_digest],
                     argv: [Time.now.to_i, max_lock_time]) == 1
      end

      def max_lock_time
        @max_lock_time ||= RunLockTimeoutCalculator.for_item(@item).seconds
      end

      def execute(_callback)
        synchronize do
          yield
        end
      end

      def create_digest
        @unique_digest ||= @item[UNIQUE_DIGEST_KEY]
        @unique_digest ||= SidekiqUniqueJobs::UniqueArgs.digest(@item)
      end
    end
  end
end
