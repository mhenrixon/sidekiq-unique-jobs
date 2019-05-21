# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class Changelogs provides access to the changelog entries
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  class Changelog < Redis::SortedSet
    def initialize
      super(CHANGELOGS)
    end

    #
    # The change log entries
    #
    # @param [String] pattern the pattern to match
    # @param [Integer] count the number of matches to return
    #
    # @return [Array<Hash>] an array of entries
    #
    def entries(pattern: "*", count: nil)
      options = {}
      options[:match] = pattern if pattern
      options[:count] = count if count

      redis do |conn|
        conn.zscan_each(key, options).to_a.map { |entry| load_json(entry[0]) }
      end
    end

    #
    # Paginate the changelog entries
    #
    # @param [Integer] cursor the cursor for this iteration
    # @param [String] pattern "*" the pattern to match
    # @param [Integer] page_size 100 the number of matches to return
    #
    # @return [Array<Integer, Integer, Array<Hash>] the total size, next cursor and changelog entries
    #
    def page(cursor, pattern: "*", page_size: 100)
      redis do |conn|
        total_size, result = conn.multi do
          conn.zcard(key)
          conn.zscan(key, cursor, match: pattern, count: page_size)
        end

        [
          total_size,
          result[0], # next_cursor
          result[1].map { |entry| load_json(entry[0]) }, # entries
        ]
      end
    end
  end
end
