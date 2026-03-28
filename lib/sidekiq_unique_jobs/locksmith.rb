# frozen_string_literal: true

module SidekiqUniqueJobs
  # Lock manager class that handles all the various locks
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class Locksmith
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Reflectable
    include SidekiqUniqueJobs::Timing
    include SidekiqUniqueJobs::Script::Caller
    include SidekiqUniqueJobs::JSON

    #
    # @!attribute [r] key
    #   @return [Key] the key used for locking
    attr_reader :key
    #
    # @!attribute [r] job_id
    #   @return [String] a sidekiq JID
    attr_reader :job_id
    #
    # @!attribute [r] config
    #   @return [LockConfig] the configuration for this lock
    attr_reader :config
    #
    # @!attribute [r] item
    #   @return [Hash] a sidekiq job hash
    attr_reader :item

    #
    # Initialize a new Locksmith instance
    #
    # @param [Hash] item a Sidekiq job hash
    # @param [Sidekiq::RedisConnection, ConnectionPool] redis_pool the redis connection
    #
    def initialize(item, redis_pool = nil)
      @item        = item
      @key         = Key.new(item[LOCK_DIGEST] || item[UNIQUE_DIGEST])
      @job_id      = item[JID]
      @config      = LockConfig.new(item)
      @redis_pool  = redis_pool
    end

    #
    # Acquire the lock for this job
    #
    # @param [Hash] options
    # @option options [Integer, nil] :wait ignored in v9 (non-blocking only)
    #
    # @return [String, nil] the job_id if locked, nil if not
    #
    def lock(wait: nil) # rubocop:disable Lint/UnusedMethodArgument
      result = call_script(:lock_v9, key.to_a_v9, lock_argv)
      return unless result

      reflect(:debug, :locked, item, result)
      job_id
    end

    #
    # Execute a block with the lock held
    #
    # @yield the block to execute
    # @return [Object, nil] the block's return value if locked, nil if not
    #
    def execute(&block)
      raise SidekiqUniqueJobs::InvalidArgument, "#execute needs a block" unless block

      locked_jid = lock
      return unless locked_jid

      yield
    end

    #
    # Release the lock for this job
    #
    # @return [String, nil] the job_id if unlocked, nil if not held
    #
    def unlock(conn = nil)
      if conn
        do_unlock(conn)
      else
        redis(redis_pool) { |rcon| do_unlock(rcon) }
      end
    end

    #
    # Deletes the lock regardless of if it has a pttl set
    #
    def delete!
      redis(redis_pool) do |conn|
        conn.call("HDEL", key.locked, job_id)
        conn.call("ZREM", key.digests, key.digest)
        conn.call("UNLINK", key.locked) if conn.call("HLEN", key.locked).zero?
      end
    end

    #
    # Deletes the lock unless it has a pttl set
    #
    def delete
      return if config.pttl.positive?

      delete!
    end

    #
    # Checks if this instance is considered locked
    #
    # @param [Redis, nil] conn optional redis connection
    #
    # @return [true, false]
    #
    def locked?(conn = nil)
      if conn
        taken?(conn)
      else
        redis { |rcon| taken?(rcon) }
      end
    end

    def to_s
      "Locksmith##{object_id}(digest=#{key} job_id=#{job_id} locked=#{locked?})"
    end

    def inspect
      to_s
    end

    def ==(other)
      key == other.key && job_id == other.job_id
    end

    private

    attr_reader :redis_pool

    def do_unlock(conn)
      result = call_script(:unlock_v9, key.to_a_v9, [job_id, config.type], conn)

      if result == job_id
        reflect(:debug, :unlocked, item, result)
        reflect(:unlocked, item)
      end

      result
    end

    def taken?(conn)
      conn.call("HEXISTS", key.locked, job_id).positive?
    end

    def lock_argv
      [job_id, config.pttl, config.type, config.limit, lock_metadata]
    end

    def lock_metadata
      dump_json(
        WORKER => item[CLASS],
        QUEUE => item[QUEUE],
        LIMIT => item[LOCK_LIMIT],
        TIMEOUT => item[LOCK_TIMEOUT],
        TTL => item[LOCK_TTL],
        TYPE => config.type,
        LOCK_ARGS => item[LOCK_ARGS],
        TIME => now_f,
        AT => item[AT],
      )
    end
  end
end
