# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class SortedSet provides convenient access to redis sorted sets
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class SortedSet < Entity
      def entries(with_scores: true)
        entrys = redis { |conn| conn.zrange(key, 0, -1, with_scores: with_scores) }
        return entrys unless with_scores

        entrys.each_with_object({}) { |pair, hash| hash[pair[0]] = pair[1] }
      end

      def rank(member)
        redis { |conn| conn.zrank(key, member) }
      end

      def score(member)
        redis { |conn| conn.zscore(key, member) }
      end

      def count
        redis { |conn| conn.zcard(key) }
      end
    end
  end
end
