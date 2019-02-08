# frozen_string_literal: true

module SidekiqUniqueJobs
  # Utility module to help manage unique digests in redis.
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Digests
    DEFAULT_COUNT = 1_000
    SCAN_PATTERN  = "*"
    CHUNK_SIZE    = 100

    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Connection
    extend self

    # Return unique digests matching pattern
    #
    # @param [String] pattern a pattern to match with
    # @param [Integer] count the maximum number to match
    # @return [Array<String>] with unique digests
    def all(pattern: SCAN_PATTERN, count: DEFAULT_COUNT)
      redis { |conn| conn.sscan_each(UNIQUE_SET, match: pattern, count: count).to_a }
    end

    # Paginate unique digests
    #
    # @param [String] pattern a pattern to match with
    # @param [Integer] cursor the maximum number to match
    # @param [Integer] page_size the current cursor position
    #
    # @return [Array<String>] with unique digests
    def page(pattern: SCAN_PATTERN, cursor: 0, page_size: 100)
      redis do |conn|
        total_size, digests = conn.multi do
          conn.scard(UNIQUE_SET)
          conn.sscan(UNIQUE_SET, cursor, match: pattern, count: page_size)
        end

        [total_size, digests[0], digests[1]]
      end
    end

    # Get a total count of unique digests
    #
    # @return [Integer] number of digests
    def count
      redis { |conn| conn.scard(UNIQUE_SET) }
    end

    # Deletes unique digest either by a digest or pattern
    #
    # @param [String] digest the full digest to delete
    # @param [String] pattern a key pattern to match with
    # @param [Integer] count the maximum number
    # @raise [ArgumentError] when both pattern and digest are nil
    # @return [Array<String>] with unique digests
    def del(digest: nil, pattern: nil, count: DEFAULT_COUNT)
      return delete_by_pattern(pattern, count: count) if pattern
      return delete_by_digest(digest) if digest

      raise ArgumentError, "either digest or pattern need to be provided"
    end

    private

    # Deletes unique digests by pattern
    #
    # @param [String] pattern a key pattern to match with
    # @param [Integer] count the maximum number
    # @return [Array<String>] with unique digests
    def delete_by_pattern(pattern, count: DEFAULT_COUNT)
      result, elapsed = timed do
        digests = all(pattern: pattern, count: count)
        batch_delete(digests)
        digests.size
      end

      log_info("#{__method__}(#{pattern}, count: #{count}) completed in #{elapsed}ms")

      result
    end

    # Get a total count of unique digests
    #
    # @param [String] digest a key pattern to match with
    def delete_by_digest(digest)
      result, elapsed = timed do
        Scripts.call(:delete_by_digest, nil, keys: [UNIQUE_SET, digest])
        count
      end

      log_info("#{__method__}(#{digest}) completed in #{elapsed}ms")

      result
    end

    def batch_delete(digests) # rubocop:disable Metrics/MethodLength
      redis do |conn|
        digests.each_slice(CHUNK_SIZE) do |chunk|
          conn.pipelined do
            chunk.each do |digest|
              conn.del digest
              conn.srem(UNIQUE_SET, digest)
              conn.del("#{digest}:EXISTS")
              conn.del("#{digest}:GRABBED")
              conn.del("#{digest}:VERSION")
              conn.del("#{digest}:AVAILABLE")
              conn.del("#{digest}:RUN:EXISTS")
              conn.del("#{digest}:RUN:GRABBED")
              conn.del("#{digest}:RUN:VERSION")
              conn.del("#{digest}:RUN:AVAILABLE")
            end
          end
        end
      end
    end

    def timed
      start = current_time
      result = yield
      elapsed = (current_time - start).round(2)
      [result, elapsed]
    end

    def current_time
      Time.now
    end
  end
end
