# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class DeleteOrphans provides deletion of orphaned digests
  #
  # @note this is a much slower version of the lua script but does not crash redis
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  class DeleteOrphans
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Script::Caller
    include SidekiqUniqueJobs::Logging

    #
    # Execute deletion of orphaned digests
    #
    #
    # @return [void]
    #
    def self.call(max_count = SidekiqUniqueJobs.config.max_orphans)
      new(max_count).call
    end

    attr_reader :orphans, :digests, :scheduled, :retried, :max_count

    #
    # Initialize a new instance of DeleteOrphans
    #
    # @param [Integer] max_count the number of orphans to delete
    #
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

    #
    # Find orphaned digests
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

    #
    # Checks if the digest exists in the {Sidekiq::ScheduledSet}
    #
    # @param [String] digest the current digest
    # @param [Redis] conn a connection to redis
    #
    # @return [true] when digest exists in scheduled set
    #
    def scheduled?(digest, conn)
      in_sorted_set?(SCHEDULE, digest, conn)
    end

    #
    # Checks if the digest exists in the {Sidekiq::RetrySet}
    #
    # @param [String] digest the current digest
    # @param [Redis] conn a connection to redis
    #
    # @return [true] when digest exists in retry set
    #
    def retried?(digest, conn)
      in_sorted_set?(RETRY, digest, conn)
    end


    #
    # Checks if the digest exists in a {Sidekiq::Queue}
    #
    # @param [String] digest the current digest
    # @param [Redis] conn a connection to redis
    #
    # @return [true] when digest exists in any queue
    #
    #
    def enqueued?(digest, conn)
      result = call_script(:find_digest_in_queues, conn, keys: [digest])
      if result
        log_debug("#{digest} found in #{result}")
        true
      else
        log_debug("#{digest} NOT found in any queues")
      end
    end

    def in_sorted_set?(key, digest, conn)
      conn.zscan_each(key, match: "*#{digest}*", count: 1).to_a.size.positive?
    end
  end
end
