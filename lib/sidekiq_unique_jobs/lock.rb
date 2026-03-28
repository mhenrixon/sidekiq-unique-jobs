# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class Lock provides access to information about a lock
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class Lock
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Timing
    include SidekiqUniqueJobs::JSON

    # @!attribute [r] key
    #   @return [Key] the lock key
    attr_reader :key

    #
    # Initialize a locked lock
    #
    # @param [String] digest a unique digest
    # @param [String] job_id a sidekiq JID
    # @param [Hash] lock_info information about the lock
    #
    # @return [Lock] a newly lock that has been locked
    #
    def self.create(digest, job_id, lock_info: {}, time: Timing.now_f, score: nil)
      lock = new(digest, time: time)
      lock.lock(job_id, lock_info, score)
      lock
    end

    #
    # Initialize a new lock
    #
    # @param [String, Key] key either a digest or an instance of a {Key}
    # @param [Float] time optional timestamp to initiate this lock with
    #
    def initialize(key, time: nil)
      @key = key.is_a?(SidekiqUniqueJobs::Key) ? key : SidekiqUniqueJobs::Key.new(key)
      time = time.to_f unless time.is_a?(Float)
      return unless time.nonzero?

      @created_at = time
    end

    #
    # Locks a job_id
    #
    # @param [String] job_id a sidekiq JID
    # @param [Hash] lock_info information about the lock
    # @param [Float] score the ZADD score
    #
    # @return [void]
    #
    def lock(job_id, lock_info = {}, score = nil)
      score ||= now_f
      metadata = dump_json(lock_info.merge("time" => now_f))

      redis do |conn|
        conn.multi do |pipeline|
          pipeline.call("HSET", key.locked, job_id, metadata)
          pipeline.call("ZADD", key.digests, score.to_s, key.digest)
        end
      end
    end

    #
    # Unlock a specific job_id
    #
    # @param [String] job_id a sidekiq JID
    #
    # @return [Integer] number of fields removed
    #
    def unlock(job_id)
      locked.del(job_id)
    end

    #
    # Deletes all the redis keys for this lock
    #
    # @return [void]
    #
    def del
      redis do |conn|
        conn.multi do |pipeline|
          pipeline.call("ZREM", DIGESTS, key.digest)
          pipeline.call("UNLINK", key.locked)
        end
      end
    end

    #
    # Returns either the initialized time or the earliest lock timestamp
    #
    # @return [Float] a timestamp
    #
    def created_at
      return @created_at if @created_at

      first_entry = locked_jids(with_values: true).values.first
      @created_at = first_entry ? parse_metadata_time(first_entry) : now_f
    end

    #
    # Returns a collection of locked job_id's
    #
    # @param [true, false] with_values provide the metadata for each lock
    #
    # @return [Hash<String, String>] when given `with_values: true`
    # @return [Array<String>] when given `with_values: false`
    #
    def locked_jids(with_values: false)
      locked.entries(with_values: with_values)
    end

    #
    # Returns lock metadata from the LOCKED hash value (JSON)
    #
    # @return [Hash, nil] parsed metadata or nil
    #
    def info
      @info ||= build_info
    end

    #
    # The locked hash
    #
    # @return [Redis::Hash] for locked JIDs
    #
    def locked
      @locked ||= Redis::Hash.new(key.locked)
    end

    def to_s
      "Lock(#{key.digest})"
    end

    def inspect
      to_s
    end

    private

    def build_info
      entries = locked_jids(with_values: true)
      return LockInfoStub.new if entries.empty?

      first_value = entries.values.first
      parsed = safe_load_json(first_value)
      parsed.is_a?(Hash) ? LockInfoStub.new(parsed) : LockInfoStub.new
    end

    def parse_metadata_time(value)
      parsed = safe_load_json(value)
      return value.to_f unless parsed.is_a?(Hash)

      parsed["time"]&.to_f || now_f
    end

    # Minimal struct to provide .value and hash-like access for web UI compat
    class LockInfoStub
      def initialize(hash = {})
        @hash = hash
      end

      def value
        @hash
      end

      def [](key)
        @hash[key]
      end

      def none?
        @hash.empty?
      end

      def any?
        !none?
      end
    end
  end
end
