# frozen_string_literal: true

module SidekiqUniqueJobs
  # Utility module to help manage unique keys in redis.
  # Useful for deleting keys that for whatever reason wasn't deleted
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Util
    DEFAULT_COUNT     = 1_000
    SCAN_PATTERN      = "*"

    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Connection
    extend self

    # Find unique keys in redis
    #
    # @param [String] pattern a pattern to scan for in redis
    # @param [Integer] count the maximum number of keys to delete
    # @return [Array<String>] an array with active unique keys
    def keys(pattern = SCAN_PATTERN, count = DEFAULT_COUNT)
      return redis(&:keys) if pattern.nil?

      redis { |conn| conn.scan_each(match: prefix(pattern), count: count).to_a }
    end

    # Find unique keys with ttl
    # @param [String] pattern a pattern to scan for in redis
    # @param [Integer] count the maximum number of keys to delete
    # @return [Hash<String, Integer>] a hash with active unique keys and corresponding ttl
    def keys_with_ttl(pattern = SCAN_PATTERN, count = DEFAULT_COUNT)
      hash = {}
      redis do |conn|
        conn.scan_each(match: prefix(pattern), count: count).each do |key|
          hash[key] = conn.ttl(key)
        end
      end
      hash
    end

    # Deletes unique keys from redis
    #
    # @param [String] pattern a pattern to scan for in redis
    # @param [Integer] count the maximum number of keys to delete
    # @return [Integer] the number of keys deleted
    def del(pattern = SCAN_PATTERN, count = 0)
      raise ArgumentError, "Please provide a number of keys to delete greater than zero" if count.zero?

      pattern = suffix(pattern)

      log_debug { "Deleting keys by: #{pattern}" }
      keys, time = timed { keys(pattern, count) }
      key_size   = keys.size
      log_debug { "#{key_size} keys found in #{time} sec." }
      _, time = timed { batch_delete(keys) }
      log_debug { "Deleted #{key_size} keys in #{time} sec." }

      key_size
    end

    private

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

    def timed
      start   = current_time
      result  = yield
      elapsed = (current_time - start).round(2)
      [result, elapsed]
    end

    def current_time
      Time.now
    end

    def prefix(key)
      return key if unique_prefix.nil?
      return key if key.start_with?("#{unique_prefix}:")

      "#{unique_prefix}:#{key}"
    end

    def suffix(key)
      return "#{key}*" unless key.end_with?(":*")

      key
    end

    def unique_prefix
      SidekiqUniqueJobs.config.unique_prefix
    end
  end
end
