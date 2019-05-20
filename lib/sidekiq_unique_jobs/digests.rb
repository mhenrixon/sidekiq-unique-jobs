# frozen_string_literal: true

module SidekiqUniqueJobs
  # Utility module to help manage unique digests in redis.
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  # TODO: Deprecate this class in favour of SidekiqUniqueJobs::Redis::Digests
  module Digests
    DEFAULT_COUNT = 1_000
    SCAN_PATTERN  = "*"
    SUFFIXES      = %w[
      :QUEUED
      :PRIMED
      :LOCKED
    ].freeze

    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Timing
    include SidekiqUniqueJobs::Script::Caller
    extend self

    # Return unique digests matching pattern
    #
    # @param [String] pattern a pattern to match with
    # @param [Integer] count the maximum number to match
    # @return [Array<String>] with unique digests
    def all(pattern: SCAN_PATTERN, count: DEFAULT_COUNT)
      digests.entries(match: prefix(pattern), count: count)
    end

    # Paginate unique digests
    #
    # @param [String] pattern a pattern to match with
    # @param [Integer] cursor the maximum number to match
    # @param [Integer] page_size the current cursor position
    #
    # @return [Array<String>] with unique digests
    def page(pattern: SCAN_PATTERN, cursor: 0, page_size: 100)
      digests.page(cursor, match: pattern, page_size: page_size)
    end

    # Get a total count of unique digests
    #
    # @return [Integer] number of digests
    def count
      digests.count
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

    def digests
      @digests ||= SidekiqUniqueJobs::Redis::Digests.new
    end

    def prefix(key)
      return key if unique_prefix.nil?
      return key if key.start_with?("#{unique_prefix}:")

      "#{unique_prefix}:#{key}"
    end

    def unique_prefix
      SidekiqUniqueJobs.config.unique_prefix
    end

    # Deletes unique digests by pattern
    #
    # @param [String] pattern a key pattern to match with
    # @param [Integer] count the maximum number
    # @return [Array<String>] with unique digests
    def delete_by_pattern(pattern, count: DEFAULT_COUNT)
      result, elapsed = timed do
        digests = all(pattern: pattern, count: count)
        SidekiqUniqueJobs::BatchDelete.new(digests).call
        digests.size
      end

      log_info("#{__method__}(#{pattern}, count: #{count}) completed in #{elapsed}ms")

      result
    end

    # Delete unique digests by digest
    #   Also deletes the :AVAILABLE, :EXPIRED etc keys
    #
    # @param [String] digest a unique digest to delete
    def delete_by_digest(digest)
      result, elapsed = timed do
        call_script(:delete_by_digest, [digest, digests.key])
      end

      log_info("#{__method__}(#{digest}) completed in #{elapsed}ms")

      result
    end
  end
end
