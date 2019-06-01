# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Upgrades locks between gem version upgrades
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  class UpgradeLocks
    BATCH_SIZE = 100
    OLD_SUFFIXES = %w[
      GRABBED
      AVAILABLE
      EXISTS
      VERSION
    ].freeze

    include SidekiqUniqueJobs::Logging

    #
    # Performs upgrade of old locks
    #
    #
    # @return [Integer] the number of upgrades locks
    #
    def self.call(conn)
      new(conn).call
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
      log_info("Start - Upgrading Locks")
      return if conn.hget(upgraded_key, SidekiqUniqueJobs.version)

      upgrade_v6_locks
      delete_unused_v6_keys
      delete_supporting_v6_keys

      conn.hset(upgraded_key, SidekiqUniqueJobs.version, SidekiqUniqueJobs.now_f)
      log_info("Done - Upgrading Locks")
      @count
    end

    private

    def upgraded_key
      @upgraded_key ||= "#{LIVE_VERSION}:UPGRADED"
    end

    def upgrade_v6_locks
      log_info("Start - Converting v6 locks to v7")
      conn.scan_each(match: "*:GRABBED", count: BATCH_SIZE) do |grabbed_key|
        locked_key = grabbed_key.gsub(":GRABBED", ":LOCKED")
        conn.hmset(locked_key, *conn.hgetall(grabbed_key).to_a)
        @count += 1
      end
      log_info("Done - Converting v6 locks to v7")
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

      conn.pipelined do
        if VersionCheck.satisfied?(redis_version, ">= 4.0.0")
          conn.unlink(*keys)
        else
          conn.del(*keys)
        end
      end
    end

    def batch_scan(match:, count:)
      cursor = "0"
      loop do
        cursor, values = conn.scan(cursor, match: match, per: count)
        yield values
        break if cursor == "0"
      end
    end

    def redis_version
      @redis_version ||= SidekiqUniqueJobs.redis_version
    end
  end
end
