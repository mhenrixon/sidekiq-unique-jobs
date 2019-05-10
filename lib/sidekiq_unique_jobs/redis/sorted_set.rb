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
        entrys = zrange(key, 0, -1, with_scores: with_scores)
        return entrys unless with_scores

        entrys.each_with_object({}) { |pair, hash| hash[pair[0]] = pair[1] }
      end

      def rank(member)
        zrank(key, member)
      end

      def score(member)
        zscore(key, member)
      end

      def count
        zcard(key)
      end
    end
  end
end
