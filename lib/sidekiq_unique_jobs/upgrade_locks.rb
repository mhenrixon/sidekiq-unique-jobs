# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Upgrades locks between gem version upgrades
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class UpgradeLocks
    #
    # @return [Integer] the number of keys to batch upgrade
    BATCH_SIZE = 100
    #
    # @return [Array<String>] suffixes for old version
    OLD_SUFFIXES = %w[
      GRABBED
      AVAILABLE
      EXISTS
      VERSION
    ].freeze

    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Connection

    #
    # Performs upgrade of old locks
    #
    #
    # @return [Integer] the number of upgrades locks
    #
    def self.call
      redis do |conn|
        new(conn).call
      end
    end

    attr_reader :conn

    def initialize(conn)
      @count         = 0
      @conn          = conn
      redis_version # Avoid pipelined calling redis_version and getting a future.
    end

    #
    # Performs upgrade of old locks
    #
    #
    # @return [Integer] the number of upgrades locks
    #
    def call
      with_logging_context do
        return log_info("Already upgraded to #{version}") if conn.hget(upgraded_key, version)
        # TODO: Needs handling of v7.0.0 => v7.0.1 where we don't want to
        return log_info("Skipping upgrade because #{DEAD_VERSION} has been set") if conn.get(DEAD_VERSION)

        log_info("Start - Upgrading Locks")

        upgrade_v8_to_v9
        merge_expiring_digests

        conn.hset(upgraded_key, version, now_f)
        log_info("Done - Upgrading Locks")
      end

      @count
    end

    private

    def upgraded_key
      @upgraded_key ||= "#{LIVE_VERSION}:UPGRADED"
    end

    def upgrade_v6_locks
      log_info("Start - Converting v6 locks to v7")
      conn.scan(match: "*:GRABBED", count: BATCH_SIZE).each do |grabbed_key|
        upgrade_v6_lock(grabbed_key)
        @count += 1
      end

      log_info("Done - Converting v6 locks to v7")
    end

    def upgrade_v6_lock(grabbed_key)
      locked_key = grabbed_key.gsub(":GRABBED", ":LOCKED")
      digest     = grabbed_key.gsub(":GRABBED", "")
      locks      = conn.hgetall(grabbed_key)

      conn.pipelined do |pipeline|
        pipeline.hmset(locked_key, *locks.to_a)
        pipeline.zadd(DIGESTS, locks.values.first, digest)
      end
    end

    def delete_unused_v6_keys
      log_info("Start - Deleting v6 keys")
      OLD_SUFFIXES.each do |suffix|
        delete_suffix(suffix)
      end
      log_info("Done - Deleting v6 keys")
    end

    def delete_supporting_v6_keys
      batch_delete("unique:keys")
    end

    def delete_suffix(suffix)
      batch_scan(match: "*:#{suffix}", count: BATCH_SIZE) do |keys|
        batch_delete(*keys)
      end
    end

    def batch_delete(*keys)
      return if keys.empty?

      conn.pipelined do |pipeline|
        pipeline.unlink(*keys)
      end
    end

    def batch_scan(match:, count:)
      cursor = "0"
      loop do
        result = conn.call("SCAN", cursor, "MATCH", match, "COUNT", count.to_s)
        cursor = result[0]
        values = result[1]
        yield values if values && !values.empty?
        break if cursor == "0"
      end
    end

    # v8→v9: Remove obsolete keys (QUEUED, PRIMED, INFO, digest STRING)
    # and their :RUN variants. The LOCKED hash is kept as-is.
    def upgrade_v8_to_v9
      log_info("Start - Removing v8 obsolete keys")

      v8_suffixes = %w[QUEUED PRIMED INFO]
      count = 0

      batch_scan(match: "uniquejobs:*:LOCKED", count: BATCH_SIZE) do |locked_keys|
        locked_keys.each do |locked_key|
          digest = locked_key.delete_suffix(":LOCKED")
          keys_to_delete = []

          # The old digest STRING key
          keys_to_delete << digest if conn.call("TYPE", digest) == "string"

          # Old suffix keys
          v8_suffixes.each do |suffix|
            key = "#{digest}:#{suffix}"
            keys_to_delete << key if conn.call("EXISTS", key).positive?
          end

          # :RUN variants
          run_digest = "#{digest}:RUN"
          keys_to_delete << run_digest if conn.call("EXISTS", run_digest).positive?
          v8_suffixes.each do |suffix|
            key = "#{run_digest}:#{suffix}"
            keys_to_delete << key if conn.call("EXISTS", key).positive?
          end
          run_locked = "#{run_digest}:LOCKED"
          run_info = "#{run_digest}:INFO"
          keys_to_delete << run_locked if conn.call("EXISTS", run_locked).positive?
          keys_to_delete << run_info if conn.call("EXISTS", run_info).positive?

          next if keys_to_delete.empty?

          conn.call("UNLINK", *keys_to_delete)
          count += keys_to_delete.size
        end
      end

      log_info("Done - Removed #{count} v8 obsolete keys")
      @count += count
    end

    # v8→v9: Merge expiring_digests into digests (unified ZSET)
    def merge_expiring_digests
      expiring_count = conn.call("ZCARD", "uniquejobs:expiring_digests")
      return if expiring_count.zero?

      log_info("Start - Merging #{expiring_count} expiring digests")

      # Move all entries from expiring_digests to digests (preserving scores)
      cursor = "0"
      moved = 0
      loop do
        cursor, entries = conn.call("ZSCAN", "uniquejobs:expiring_digests", cursor, "COUNT", "100")

        entries.each_slice(2) do |digest, score|
          conn.call("ZADD", DIGESTS, score, digest)
          moved += 1
        end

        break if cursor == "0"
      end

      conn.call("UNLINK", "uniquejobs:expiring_digests")
      log_info("Done - Merged #{moved} expiring digests")
      @count += moved
    end

    def version
      SidekiqUniqueJobs.version
    end

    def now_f
      SidekiqUniqueJobs.now_f
    end

    def redis_version
      @redis_version ||= SidekiqUniqueJobs.config.redis_version
    end

    def logging_context
      if logger_context_hash?
        { "uniquejobs" => :upgrade_locks }
      else
        "uniquejobs-upgrade_locks"
      end
    end
  end
end
