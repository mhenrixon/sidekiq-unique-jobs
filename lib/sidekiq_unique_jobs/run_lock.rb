# Cross-process locking using Redis.
require 'sidekiq_unique_jobs/run_lock_failed'

module SidekiqUniqueJobs
  class RunLock
    extend Forwardable

    def self.synchronize(key, redis, options = {}, &blk)
      new(key, redis, options).synchronize(&blk)
    end

    def_delegators :'SidekiqUniqueJobs.config', :default_run_lock_retries,
                   :default_run_lock_retry_interval, :default_run_lock_expire

    attr_reader :options

    def initialize(key, redis, options = {})
      @key = "#{key}:run"
      @redis = redis
      @options = options
      @mutex = Mutex.new
    end

    # NOTE wrapped in mutex to maintain its semantics
    def synchronize
      @mutex.lock
      sleep 0.001 until locked?

      yield

    ensure
      @redis.del @key
      @mutex.unlock
    end

    private

    # rubocop:disable MethodLength
    def locked?
      got_lock = false
      if @redis.setnx @key, Time.now.to_i + 60
        @redis.expire @key, 60
        got_lock = true
      else
        begin
          @redis.watch @key
          time = @redis.get @key
          if time && time.to_i < Time.now.to_i
            got_lock = @redis.multi do
              @redis.set @key, Time.now.to_i + 60
            end
          end
        ensure
          @redis.unwatch
        end
      end

      got_lock
    end
    # rubocop:enable MethodLength

    def run_lock_retries
      options['run_lock_retries'] || default_run_lock_retries.to_i
    end

    def run_lock_retry_interval
      options['run_lock_retry_interval'] || default_run_lock_retry_interval.to_i
    end

    def run_lock_expire
      options['run_lock_expire'] || default_run_lock_expire.to_i
    end
  end
end
