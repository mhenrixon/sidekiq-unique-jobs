# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class Changelogs provides access to the changelog entries
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class Changelogs < SortedSet
      def initialize
        super(SidekiqUniqueJobs::CHANGELOG_ZSET)
      end

      #
      # The entries for this changelog
      #
      # @param [String] digest the digest to search for
      #
      # @return [Array<Hash<String, Object>>] an array of changelog entries
      #
      def entries(match: "*", count: nil)
        options = {}
        options[:match] = match if match
        options[:count] = count if count
        redis do |conn|
          conn.zscan_each(key, options).to_a.map { |entry| load_json(entry[0]) }
        end
      end

      def page(cursor, match: "*", page_size: 100)
        redis do |conn|
          total_size, digests = conn.multi do
            conn.zcard(key)
            conn.zscan(key, cursor, match: match, count: page_size)
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
end
