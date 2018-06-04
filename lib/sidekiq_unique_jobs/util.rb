# frozen_string_literal: true

module SidekiqUniqueJobs
  module Util
    COUNT             = 'COUNT'
    DEFAULT_COUNT     = 1_000
    EXPIRE_BATCH_SIZE = 100
    SCAN_METHOD       = 'SCAN'
    SCAN_PATTERN      = '*'

    extend self # rubocop:disable Style/ModuleFunction

    def keys(pattern = SCAN_PATTERN, count = DEFAULT_COUNT)
      connection { |conn| conn.scan_each(match: prefix(pattern), count: count).to_a }
    end

    # Deletes unique keys from redis
    #
    #
    # @param pattern [String] a pattern to scan for in redis
    # @param count [Integer] the maximum number of keys to delete
    # @param dry_run [Boolean] set to false to perform deletion, `true` or `false`
    # @return [Boolean] report success
    # @raise [SidekiqUniqueJobs::LockTimeout] when lock fails within configured timeout
    def del(pattern = SCAN_PATTERN, count = 0, dry_run = true)
      raise ArgumentError, 'Please provide a number of keys to delete greater than zero' if count.zero?
      pattern = "#{pattern}:*" unless pattern.end_with?(':*')

      logger.debug { "Deleting keys by: #{pattern}" }
      keys, time = timed { keys(pattern, count) }
      logger.debug { "#{keys.size} matching keys found in #{time} sec." }
      keys = dry_run(keys)
      logger.debug { "#{keys.size} matching keys after post-processing" }
      unless dry_run
        logger.debug { "deleting #{keys}..." }
        _, time = timed { batch_delete(keys) }
        logger.debug { "Deleted in #{time} sec." }
      end
      keys.size
    end

    private

    def batch_delete(keys)
      connection do |conn|
        keys.each_slice(500) do |chunk|
          conn.pipelined do
            chunk.each do |key|
              conn.del key
            end
          end
        end
      end
    end

    def dry_run(keys, pattern = nil)
      return keys if pattern.nil?
      regex = Regexp.new(pattern)
      keys.select { |k| regex.match k }
    end

    def timed(&_block)
      start = Time.now
      result = yield
      elapsed = (Time.now - start).round(2)
      [result, elapsed]
    end

    def prefix_keys(keys)
      keys = Array(keys).flatten.compact
      keys.map { |key| prefix(key) }
    end

    def prefix(key)
      return key if unique_prefix.nil?
      return key if key.start_with?("#{unique_prefix}:")
      "#{unique_prefix}:#{key}"
    end

    def unique_prefix
      SidekiqUniqueJobs.config.unique_prefix
    end

    def connection(&block)
      SidekiqUniqueJobs.connection(&block)
    end

    def logger
      SidekiqUniqueJobs.logger
    end
  end
end
