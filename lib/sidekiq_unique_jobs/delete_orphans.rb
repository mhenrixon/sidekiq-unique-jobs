# frozen_string_literal: true

module SidekiqUniqueJobs
  class DeleteOrphans
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Script::Caller
    include SidekiqUniqueJobs::Logging

    def self.call
      new.call
    end

    attr_reader :orphans, :digests, :scheduled, :retried, :max_count

    def initialize(max_count = SidekiqUniqueJobs.config.max_orphans)
      @orphans   = []
      @digests   = Redis::Digests.new
      @scheduled = Redis::SortedSet.new(SCHEDULE)
      @retried   = Redis::SortedSet.new(RETRY)
      @max_count = max_count
    end

    #
    # Delete orphaned digests
    #
    #
    # @return [<type>] <description>
    #
    def call
      redis do |conn|
        orphans = find_orphans(conn)
        BatchDelete.call(orphans, conn)
      end
    end
    # scheduled?(digest, conn)
    # retried?(digest, conn)
    # enqueued?(digest, conn)
    #
    # Get orphaned digests
    #
    #
    # @return [Array<String>] an array of orphaned digests
    #
    def find_orphans(conn)
      conn.zrevrange(digests.key, 0, -1).each_with_object([]) do |digest, result|
        next if scheduled?(digest, conn)
        next if retried?(digest, conn)
        next if enqueued?(digest, conn)

        result << digest
        break if result.size >= max_count

        result
      end
    end

    def scheduled?(digest, conn)
      in_sorted_set?(SCHEDULE, digest, conn)
    end

    def retried?(digest, conn)
      in_sorted_set?(RETRY, digest, conn)
    end

    def in_sorted_set?(key, digest, conn)
      conn.zscan_each(key, match: "*#{digest}*", count: 1).to_a.size.positive?
    end


    def enqueued?(digest, conn)
      result = call_script(:find_digest_in_queues, conn, keys: [digest])
      if result
        log_debug("#{digest} found in #{result}")
        true
      else
        log_debug("#{digest} NOT found in any queues")
      end
    end
  end
end
