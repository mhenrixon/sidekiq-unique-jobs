# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class Lock provides access to information about a lock
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class Lock
      attr_reader :key

      def initialize(key)
        @key = get_key(key)
      end

      def all_jids
        (queued_jids + primed_jids + locked_jids).uniq
      end

      def locked_jids(with_values: false)
        locked_hash.entries(with_values: with_values)
      end

      def queued_jids
        queued_list.entries
      end

      def primed_jids
        primed_list.entries
      end

      def changelog_entries
        changelogs.entries(match: "*#{key.digest}*")
      end

      def digest_key
        @digest_key ||= Redis::String.new(key.digest)
      end

      def queued_list
        @queued_list ||= Redis::List.new(key.queued)
      end

      def primed_list
        @primed_list ||= Redis::List.new(key.primed)
      end

      def locked_hash
        @locked_hash ||= Redis::Hash.new(key.locked)
      end

      def changelogs
        @changelogs ||= Redis::Changelogs.new
      end

      private

      def get_key(key)
        if key.is_a?(SidekiqUniqueJobs::Key)
          key
        else
          SidekiqUniqueJobs::Key.new(key)
        end
      end
    end
  end
end
