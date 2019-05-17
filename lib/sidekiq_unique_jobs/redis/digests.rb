# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class Changelogs provides access to the changelog entries
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class Digests < SortedSet
      def initialize
        super(SidekiqUniqueJobs::DIGESTS)
      end

      #
      # The entries for this changelog
      #
      # @param [String] digest the digest to search for
      #
      # @return [Array<String>] an array of digests matching the given pattern
      #
      def entries(match: "*", count: nil)
        options = {}
        options[:match] = match
        options[:count] = count if count

        result = redis { |conn| conn.zscan_each(key, options).to_a }

        result.each_with_object({}) do |entry, hash|
          hash[entry[0]] = entry[1]
        end
      end

      #
      # Returns a paginated
      #
      # @param [Integer] cursor the cursor for this iteration
      # @param [String] match: "*" the match pattern to search for
      # @param [Integer] page_size: 100 the size per page
      #
      # @return [Array<Integer, Integer, Array<String>>] total_size, next_cursor, entries
      #
      def page(cursor, match: "*", page_size: 100)
        redis do |conn|
          total_size, digests = conn.multi do
            conn.zcard(key)
            conn.zscan(key, cursor, match: match, count: page_size)
          end

          [
            total_size,
            digests[0], # next_cursor
            digests[1], # entries
          ]
        end
      end
    end
  end
end
