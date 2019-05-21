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
    # @param [String] digest the digest to search for
    #
    # @return [Array<Hash<String, Object>>] an array of changelog entries
    #
    def entries(pattern: "*", count: nil)
      options = {}
      options[:match] = pattern if pattern
      options[:count] = count if count

      redis do |conn|
        conn.zscan_each(key, options).to_a.map { |entry| load_json(entry[0]) }
      end
    end

    def page(cursor, pattern: "*", page_size: 100)
      redis do |conn|
        total_size, digests = conn.multi do
          conn.zcard(key)
          conn.zscan(key, cursor, match: pattern, count: page_size)
        end

        [
          total_size,
          digests[0], # next_cursor
          digests[1].map { |entry| load_json(entry[0]) }, # entries
        ]
      end
    end
  end
end
