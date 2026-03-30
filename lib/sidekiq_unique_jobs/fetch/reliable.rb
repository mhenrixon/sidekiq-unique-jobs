# frozen_string_literal: true

require "sidekiq/fetch"

module SidekiqUniqueJobs
  module Fetch
    # Reliable fetch strategy using LMOVE to atomically move jobs from
    # queues to a per-process working list. Jobs are tracked in the
    # working list until acknowledged, providing crash recovery.
    #
    # Features:
    # - Atomic LMOVE from queue to working list (no job loss on crash)
    # - Lock validation at fetch time via Lua script
    # - Per-process heartbeat for dead process detection
    # - Startup recovery of orphaned working lists
    # - Compatible with all Sidekiq queue ordering modes
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Reliable
      include Sidekiq::Component
      include SidekiqUniqueJobs::Script::Caller
      include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::Reflectable
      include SidekiqUniqueJobs::JSON

      # Polling timeout — same as Sidekiq::BasicFetch
      TIMEOUT = 2

      # Heartbeat TTL — must be longer than TIMEOUT to avoid false death detection
      HEARTBEAT_TTL = 60

      # How often to refresh heartbeat
      HEARTBEAT_INTERVAL = 20

      # @param capsule [Sidekiq::Capsule]
      def initialize(capsule)
        @config = capsule
        @strictly_ordered_queues = capsule.mode == :strict
        @queues = capsule.queues.map { |q| "queue:#{q}" }
        @queues.uniq! if @strictly_ordered_queues
        @identity = "#{Socket.gethostname}:#{Process.pid}:#{SecureRandom.hex(6)}"
        @working_key = Key.working(@identity)
        @done = false

        start_heartbeat
        recover_orphans
      end

      # Fetch the next job from any configured queue.
      #
      # Uses non-blocking LMOVE + lock validation (via Lua) for all queues
      # except the last, where it uses blocking BLMOVE to avoid CPU spin.
      #
      # @return [UnitOfWork, nil]
      def retrieve_work
        return nil if @done

        qs = queues_cmd
        return nil if qs.empty?

        redis do |conn|
          # Non-blocking: try each queue except the last
          if qs.size > 1
            qs[0..-2].each do |queue|
              work = fetch_nonblocking(conn, queue)
              return work if work
            end
          end

          # Blocking: wait on the last queue
          fetch_blocking(conn, qs.last)
        end
      end

      # Called during shutdown to return in-progress jobs to their queues.
      #
      # @param inprogress [Array<UnitOfWork>] jobs to requeue
      def bulk_requeue(inprogress)
        @done = true
        @heartbeat_thread&.join(1)
        return if inprogress.empty?

        logger.debug { "Re-queueing #{inprogress.size} jobs" }

        redis do |conn|
          conn.pipelined do |pipeline|
            inprogress.each do |uow|
              pipeline.call("RPUSH", uow.queue, uow.job)
              pipeline.call("LREM", @working_key, 1, uow.job)
            end
          end
        end

        logger.info("Pushed #{inprogress.size} jobs back to Redis")
      rescue StandardError => ex
        logger.warn("Failed to requeue #{inprogress.size} jobs: #{ex.message}")
      end

      private

      # Non-blocking fetch using Lua script: LMOVE + lock validation
      def fetch_nonblocking(conn, queue)
        result = call_script(:fetch, [queue, @working_key], [], conn)
        return unless result

        job_json, lock_valid = result
        return unless job_json

        if lock_valid.zero?
          parsed = safe_load_json(job_json)
          reflect(:lock_expired_at_fetch, parsed) if parsed.is_a?(Hash)
        end

        UnitOfWork.new(queue, job_json, @config, @working_key)
      end

      # Blocking fetch on the last queue — can't use Lua for blocking ops
      def fetch_blocking(conn, queue)
        job_json = conn.blocking_call(TIMEOUT, "BLMOVE", queue, @working_key, "RIGHT", "LEFT", TIMEOUT)
        return unless job_json

        validate_lock(conn, job_json)

        UnitOfWork.new(queue, job_json, @config, @working_key)
      end

      def validate_lock(conn, job_json)
        parsed = safe_load_json(job_json)
        return unless parsed.is_a?(Hash)

        digest = parsed[LOCK_DIGEST]
        jid = parsed[JID]
        return unless digest && jid

        reflect(:lock_expired_at_fetch, parsed) unless conn.call("HEXISTS", "#{digest}:LOCKED", jid).positive?
      rescue StandardError
        # Never prevent job processing
      end

      def queues_cmd
        if @strictly_ordered_queues
          @queues
        else
          permute = @queues.shuffle
          permute.uniq!
          permute
        end
      end

      # Heartbeat: set a key with TTL so other processes can detect if we're dead
      def start_heartbeat
        set_heartbeat

        @heartbeat_thread = Thread.new do
          loop do
            break if @done

            sleep HEARTBEAT_INTERVAL
            set_heartbeat
          rescue StandardError => ex
            logger.warn("Heartbeat error: #{ex.message}")
            sleep 1
          end
        end
      end

      def set_heartbeat
        redis do |conn|
          conn.call("SET", Key.heartbeat(@identity), "1", "EX", HEARTBEAT_TTL.to_s)
        end
      end

      # On startup: find working lists from dead processes and recover their jobs
      def recover_orphans
        recovered = 0

        redis do |conn|
          cursor = "0"
          loop do
            cursor, keys = conn.call("SCAN", cursor, "MATCH", "uniquejobs:working:*", "COUNT", "100")
            keys.each do |working_key|
              wk_identity = working_key.delete_prefix("uniquejobs:working:")
              next if wk_identity == @identity

              heartbeat_key = Key.heartbeat(wk_identity)
              next if conn.call("EXISTS", heartbeat_key).positive?

              # Dead process — use LRANGE + UNLINK (batch, not per-item RPOP)
              jobs = conn.call("LRANGE", working_key, 0, -1)
              jobs.each do |job_json|
                parsed = safe_load_json(job_json)
                queue = if parsed.is_a?(Hash) && parsed["queue"]
                  "queue:#{parsed['queue']}"
                else
                  "queue:default"
                end
                conn.call("RPUSH", queue, job_json)
                recovered += 1
              end

              conn.call("UNLINK", working_key)
            end
            break if cursor == "0"
          end
        end

        logger.info("Recovered #{recovered} orphaned jobs") if recovered.positive?
      rescue StandardError => ex
        logger.warn("Orphan recovery failed: #{ex.message}")
      end

      # UnitOfWork holds a fetched job with lock-aware acknowledge and requeue
      class UnitOfWork
        include SidekiqUniqueJobs::Script::Caller
        include SidekiqUniqueJobs::JSON
        include SidekiqUniqueJobs::Logging

        attr_reader :queue, :job, :config

        def initialize(queue, job, config, working_key)
          @queue = queue
          @job = job
          @config = config
          @working_key = working_key
        end

        def queue_name
          queue.delete_prefix("queue:")
        end

        # Called after successful job completion.
        # Atomically removes from working list and unlocks via Lua.
        def acknowledge
          parsed = safe_load_json(job)
          digest = parsed.is_a?(Hash) ? parsed[LOCK_DIGEST] : nil
          jid = parsed.is_a?(Hash) ? parsed[JID] : nil
          lock_type = parsed.is_a?(Hash) ? parsed["lock"] : nil

          if digest && jid
            call_script(
              :ack,
              [@working_key, "#{digest}:LOCKED", SidekiqUniqueJobs::DIGESTS],
              [job, jid, digest, lock_type.to_s],
            )
          else
            # Not a unique job — just remove from working list
            Sidekiq.redis { |conn| conn.call("LREM", @working_key, 1, job) }
          end
        rescue StandardError => ex
          # Safety net: never let ack failure prevent Sidekiq from continuing
          log_warn("Acknowledge failed: #{ex.message}")
          Sidekiq.redis { |conn| conn.call("LREM", @working_key, 1, job) }
        end

        # Called to return a job to the queue during shutdown.
        # Preserves locks — the job is going back, not being abandoned.
        def requeue
          Sidekiq.redis do |conn|
            conn.pipelined do |pipeline|
              pipeline.call("RPUSH", queue, job)
              pipeline.call("LREM", @working_key, 1, job)
            end
          end
        end
      end
    end
  end
end
