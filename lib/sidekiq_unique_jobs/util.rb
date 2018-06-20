# frozen_string_literal: true

module SidekiqUniqueJobs
  module Util
    COUNT             = 'COUNT'
    DEFAULT_COUNT     = 1_000
    EXPIRE_BATCH_SIZE = 100
    SCAN_METHOD       = 'SCAN'
    SCAN_PATTERN      = '*'

    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Connection
    extend self # rubocop:disable Style/ModuleFunction

    def keys(pattern = SCAN_PATTERN, count = DEFAULT_COUNT)
      return redis(&:keys) if pattern.nil?
      redis { |conn| conn.scan_each(match: prefix(pattern), count: count).to_a }
    end

    # Deletes unique keys from redis
    #
    #
    # @param pattern [String] a pattern to scan for in redis
    # @param count [Integer] the maximum number of keys to delete
    # @return [Boolean] report success
    def del(pattern = SCAN_PATTERN, count = 0)
      raise ArgumentError, 'Please provide a number of keys to delete greater than zero' if count.zero?
      pattern = "#{pattern}:*" unless pattern.end_with?(':*')

      log_debug { "Deleting keys by: #{pattern}" }
      keys, time = timed { keys(pattern, count) }
      key_size   = keys.size
      log_debug { "#{key_size} keys found in #{time} sec." }
      _, time = timed { batch_delete(keys) }
      log_debug { "Deleted #{key_size} keys in #{time} sec." }

      key_size
    end

    def batch_delete(keys)
      redis do |conn|
        keys.each_slice(500) do |chunk|
          conn.pipelined do
            chunk.each do |key|
              conn.del key
            end
          end
        end
      end
    end

    def timed(&_block)
      start = Time.now
      result = yield
      elapsed = (Time.now - start).round(2)
      [result, elapsed]
    end

    def prefix_keys(keys)
      keys = Array(keys).compact
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
  end
end
