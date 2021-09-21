# frozen_string_literal: true

module SidekiqUniqueJobs
  module Orphans
    #
    # Class DeleteOrphans provides deletion of orphaned digests
    #
    # @note this is a much slower version of the lua script but does not crash redis
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class RubyReaper < Reaper
      #
      # @return [String] the suffix for :RUN locks
      RUN_SUFFIX = ":RUN"
      #
      # @!attribute [r] digests
      #   @return [SidekiqUniqueJobs::Digests] digest collection
      attr_reader :digests
      #
      # @!attribute [r] scheduled
      #   @return [Redis::SortedSet] the Sidekiq ScheduleSet
      attr_reader :scheduled
      #
      # @!attribute [r] retried
      #   @return [Redis::SortedSet] the Sidekiq RetrySet
      attr_reader :retried

      #
      # Initialize a new instance of DeleteOrphans
      #
      # @param [Redis] conn a connection to redis
      #
      def initialize(conn)
        super(conn)
        @digests   = SidekiqUniqueJobs::Digests.new
        @scheduled = Redis::SortedSet.new(SCHEDULE)
        @retried   = Redis::SortedSet.new(RETRY)
      end

      #
      # Delete orphaned digests
      #
      #
      # @return [Integer] the number of reaped locks
      #
      def call
        BatchDelete.call(orphans, conn)
      end

      #
      # Find orphaned digests
      #
      #
      # @return [Array<String>] an array of orphaned digests
      #
      def orphans
        conn.zrevrange(digests.key, 0, -1).each_with_object([]) do |digest, memo|
          next if belongs_to_job?(digest)

          memo << digest
          break if memo.size >= reaper_count
        end
      end

      #
      # Checks if the digest has a matching job.
      #   1. It checks the scheduled set
      #   2. It checks the retry set
      #   3. It goes through all queues
      #
      #
      # @param [String] digest the digest to search for
      #
      # @return [true] when either of the checks return true
      # @return [false] when no job was found for this digest
      #
      def belongs_to_job?(digest)
        scheduled?(digest) || retried?(digest) || enqueued?(digest) || active?(digest)
      end

      #
      # Checks if the digest exists in the Sidekiq::ScheduledSet
      #
      # @param [String] digest the current digest
      #
      # @return [true] when digest exists in scheduled set
      #
      def scheduled?(digest)
        in_sorted_set?(SCHEDULE, digest)
      end

      #
      # Checks if the digest exists in the Sidekiq::RetrySet
      #
      # @param [String] digest the current digest
      #
      # @return [true] when digest exists in retry set
      #
      def retried?(digest)
        in_sorted_set?(RETRY, digest)
      end

      #
      # Checks if the digest exists in a Sidekiq::Queue
      #
      # @param [String] digest the current digest
      #
      # @return [true] when digest exists in any queue
      #
      def enqueued?(digest)
        Sidekiq.redis do |conn|
          queues(conn) do |queue|
            entries(conn, queue) do |entry|
              return true if entry.include?(digest)
            end
          end

          false
        end
      end

      def active?(digest) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        Sidekiq.redis do |conn|
          procs = conn.sscan_each("processes").to_a
          return false if procs.empty?

          procs.sort.each do |key|
            valid, workers = conn.pipelined do
              # TODO: Remove the if statement in the future
              if conn.respond_to?(:exists?)
                conn.exists?(key)
              else
                conn.exists(key)
              end
              conn.hgetall("#{key}:workers")
            end

            next unless valid
            next unless workers.any?

            workers.each_pair do |_tid, job|
              next unless (item = safe_load_json(job))

              payload = safe_load_json(item[PAYLOAD])

              return true if match?(digest, payload[LOCK_DIGEST])
              return true if considered_active?(payload[CREATED_AT])
            end
          end

          false
        end
      end

      def match?(key_one, key_two)
        return false if key_one.nil? || key_two.nil?

        key_one.delete_suffix(RUN_SUFFIX) == key_two.delete_suffix(RUN_SUFFIX)
      end

      def considered_active?(time_f)
        (Time.now - reaper_timeout).to_f < time_f
      end

      #
      # Loops through all the redis queues and yields them one by one
      #
      # @param [Redis] conn the connection to use for fetching queues
      #
      # @return [void]
      #
      # @yield queues one at a time
      #
      def queues(conn, &block)
        conn.sscan_each("queues", &block)
      end

      def entries(conn, queue, &block) # rubocop:disable Metrics/MethodLength
        queue_key    = "queue:#{queue}"
        initial_size = conn.llen(queue_key)
        deleted_size = 0
        page         = 0
        page_size    = 50

        loop do
          range_start = page * page_size - deleted_size
          range_end   = range_start + page_size - 1
          entries     = conn.lrange(queue_key, range_start, range_end)
          page       += 1

          break if entries.empty?

          entries.each(&block)

          deleted_size = initial_size - conn.llen(queue_key)
        end
      end

      #
      # Checks a sorted set for the existance of this digest
      #
      #
      # @param [String] key the key for the sorted set
      # @param [String] digest the digest to scan for
      #
      # @return [true] when found
      # @return [false] when missing
      #
      def in_sorted_set?(key, digest)
        conn.zscan_each(key, match: "*#{digest}*", count: 1).to_a.any?
      end
    end
  end
end
