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
      include SidekiqUniqueJobs::Timing

      #
      # @return [Integer] a best guess of Sidekiq::Launcher::BEAT_PAUSE
      SIDEKIQ_BEAT_PAUSE = 10
      #
      # @return [String] the suffix for :RUN locks
      RUN_SUFFIX = ":RUN"
      #
      # @return [Integer] the maximum combined length of sidekiq queues for running the reaper
      MAX_QUEUE_LENGTH = 1000
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
      # @!attribute [r] start_time
      #   @return [Integer] The timestamp this execution started represented as Time (used for locks)
      attr_reader :start_time

      #
      # @!attribute [r] start_time
      #   @return [Integer] The clock stamp this execution started represented as integer
      #      (used for redis compatibility as it is more accurate than time)
      attr_reader :start_source

      #
      # @!attribute [r] timeout_ms
      #   @return [Integer] The allowed ms before timeout
      attr_reader :timeout_ms

      #
      # Initialize a new instance of DeleteOrphans
      #
      # @param [Redis] conn a connection to redis
      #
      def initialize(conn)
        super
        @digests      = SidekiqUniqueJobs::Digests.new
        @scheduled    = Redis::SortedSet.new(SCHEDULE)
        @retried      = Redis::SortedSet.new(RETRY)
        @start_time   = Time.now
        @start_source = time_source.call
        @timeout_ms   = SidekiqUniqueJobs.config.reaper_timeout * 1000
      end

      #
      # Delete orphaned digests
      #
      #
      # @return [Integer] the number of reaped locks
      #
      def call
        return if queues_very_full?

        BatchDelete.call(expired_digests, conn)
        BatchDelete.call(orphans, conn)

        # orphans.each_slice(500) do |chunk|
        #   conn.pipelined do |pipeline|
        #     chunk.each do |digest|
        #       next if belongs_to_job?(digest)

        #       pipeline.zadd(ORPHANED_DIGESTS, now_f, digest)
        #     end
        #   end
        # end
      end

      def expired_digests
        conn.zrange(EXPIRING_DIGESTS, 0, max_score, "byscore")
      end

      def orphaned_digests
        conn.zrange(ORPHANED_DIGESTS, 0, max_score, "byscore")
      end

      def max_score
        (start_time - reaper_timeout - SIDEKIQ_BEAT_PAUSE).to_f
      end

      #
      # Find orphaned digests
      #
      #
      # @return [Array<String>] an array of orphaned digests
      #
      def orphans
        orphans = []
        page    = 0
        per     = reaper_count * 2
        results = digests.byscore(0, max_score, offset: page * per, count: (page + 1) * per)

        while results.size.positive?
          results.each do |digest|
            break if timeout?
            next if belongs_to_job?(digest)

            orphans << digest
            break if orphans.size >= reaper_count
          end

          break if timeout?
          break if orphans.size >= reaper_count

          page += 1
          results = digests.byscore(0, max_score, offset: page * per, count: (page + 1) * per)
        end

        orphans
      end

      def timeout?
        elapsed_ms >= timeout_ms
      end

      def elapsed_ms
        time_source.call - start_source
      end

      #
      # Checks if the digest has a matching job.
      #   1. It checks the scheduled set
      #   2. It checks the retry set
      #   3. It goes through all queues
      #   4. It checks active processes
      #
      # Note: Uses early returns for short-circuit evaluation.
      # We can't pipeline ZSCAN operations as they're iterative.
      #
      # @param [String] digest the digest to search for
      #
      # @return [true] when either of the checks return true
      # @return [false] when no job was found for this digest
      #
      def belongs_to_job?(digest)
        # Short-circuit: Return immediately if found in scheduled set
        return true if scheduled?(digest)

        # Short-circuit: Return immediately if found in retry set
        return true if retried?(digest)

        # Short-circuit: Return immediately if found in any queue
        return true if enqueued?(digest)

        # Last check: active processes
        active?(digest)
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

      def active?(digest)
        Sidekiq.redis do |conn|
          procs = conn.sscan("processes").to_a
          return false if procs.empty?

          procs.sort.each do |key|
            valid, workers = conn.pipelined do |pipeline|
              # TODO: Remove the if statement in the future
              if pipeline.respond_to?(:exists?)
                pipeline.exists?(key)
              else
                pipeline.exists(key)
              end
              pipeline.hgetall("#{key}:work")
            end

            next unless valid
            next unless workers.any?

            workers.each_pair do |_tid, job|
              next unless (item = safe_load_json(job))

              next unless (raw_payload = item[PAYLOAD])

              payload = safe_load_json(raw_payload)

              return true if match?(digest, payload[LOCK_DIGEST])
              return true if considered_active?(time_from_payload_timestamp(payload[CREATED_AT]).to_f)
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
        max_score < time_f
      end

      def time_from_payload_timestamp(timestamp)
        if timestamp.is_a?(Float)
          # < Sidekiq 8, timestamps were stored as fractional seconds since the epoch
          Time.at(timestamp).utc
        else
          Time.at(timestamp / 1000, timestamp % 1000, :millisecond)
        end
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
        conn.sscan("queues").each(&block)
      end

      def entries(conn, queue, &block)
        queue_key    = "queue:#{queue}"
        initial_size = conn.llen(queue_key)
        deleted_size = 0
        page         = 0
        page_size    = 50

        loop do
          range_start = (page * page_size) - deleted_size

          range_end   = range_start + page_size - 1
          entries     = conn.lrange(queue_key, range_start, range_end)
          page       += 1

          break if entries.empty?

          entries.each(&block)

          deleted_size = initial_size - conn.llen(queue_key)

          # The queue is growing, not shrinking, just keep looping
          deleted_size = 0 if deleted_size.negative?
        end
      end

      # If sidekiq queues are very full, it becomes highly inefficient for the reaper
      # because it must check every queued job to verify a digest is safe to delete
      # The reaper checks queued jobs in batches of 50, adding 2 reads per digest
      # With a queue length of 1,000 jobs, that's over 20 extra reads per digest.
      def queues_very_full?
        total_queue_size = 0
        Sidekiq.redis do |conn|
          queues(conn) do |queue|
            total_queue_size += conn.llen("queue:#{queue}")

            return true if total_queue_size > MAX_QUEUE_LENGTH
          end
        end
        false
      end

      #
      # Checks a sorted set for the existance of this digest
      #
      # Note: Must use pattern matching because sorted sets contain job JSON strings,
      # not just digests. The digest is embedded in the JSON as the "lock_digest" field.
      # ZSCORE won't work here as we need to search within the member content.
      #
      # @param [String] key the key for the sorted set
      # @param [String] digest the digest to scan for
      #
      # @return [true] when found
      # @return [false] when missing
      #
      def in_sorted_set?(key, digest)
        conn.zscan(key, match: "*#{digest}*", count: 1).to_a.any?
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
