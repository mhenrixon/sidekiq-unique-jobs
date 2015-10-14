module SidekiqUniqueJobs
  module Lock
    class WhileExecuting
      def self.synchronize(item, redis_pool = nil, &block)
        new(item, redis_pool).synchronize(&block)
      end

      def initialize(item, redis_pool = nil)
        @item = item
        @mutex = Mutex.new
        @redis_pool = redis_pool
        @unique_digest = "#{create_digest}:run"
        yield self if block_given?
      end

      def synchronize
        @mutex.lock
        sleep 0.001 until locked?

        yield

      ensure
        SidekiqUniqueJobs.connection(@redis_pool) { |c| c.del @unique_digest }
        @mutex.unlock
      end

      def locked?
        Scripts.call(:synchronize, @redis_pool, keys: [@unique_digest], argv: [Time.now.to_i]) == 1
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
