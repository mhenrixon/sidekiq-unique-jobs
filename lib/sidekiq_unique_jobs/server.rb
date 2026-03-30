# frozen_string_literal: true

module SidekiqUniqueJobs
  # Server-side lifecycle management for sidekiq-unique-jobs.
  #
  # Handles startup (migration, metrics, reaper) and shutdown (flush, cleanup).
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class Server
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Logging

    DEATH_HANDLER = (lambda do |job, _ex|
      return unless (digest = job["lock_digest"])

      SidekiqUniqueJobs::Digests.new.delete_by_digest(digest)
    end).freeze

    class << self
      attr_reader :metrics

      def configure(config)
        config.on(:startup)  { start }
        config.on(:shutdown) { stop }

        return unless config.respond_to?(:death_handlers)

        config.death_handlers << DEATH_HANDLER
      end

      def start
        SidekiqUniqueJobs::UpgradeLocks.call
        start_metrics
        start_reaper
      end

      def stop
        @reaper_task&.shutdown
        @flush_task&.shutdown
        @metrics&.flush
        release_reaper_mutex
      end

      # Run the reaper once (used by tests and manual invocation).
      #
      # When called from the TimerTask, acquires a Redis mutex so only
      # one Sidekiq process reaps at a time. Direct calls (tests, console)
      # skip the mutex.
      #
      # @param mutex [Boolean] whether to acquire the Redis mutex
      # @return [Integer] number of stale digests removed
      def reap(mutex: false)
        if mutex
          return 0 unless acquire_reaper_mutex
        end

        log_info("Reaper cycle starting")

        count = Orphans::Reaper.call

        if count.positive?
          log_info("Reaper removed #{count} orphaned digests")
        else
          log_info("Reaper found no orphans")
        end
        count
      rescue StandardError => ex
        log_error("Reaper error: #{ex.class}: #{ex.message}")
        0
      end

      private

      # Acquire exclusive reaper mutex via SET NX EX.
      # TTL is interval + 2% drift so it expires if the holder dies.
      # Returns true if this process won the mutex.
      def acquire_reaper_mutex
        interval = SidekiqUniqueJobs.config.reaper_interval
        ttl = interval + (interval * 0.02).ceil

        SidekiqUniqueJobs.redis do |conn|
          conn.call("SET", UNIQUE_REAPER, Process.pid.to_s, "EX", ttl.to_s, "NX") == "OK"
        end
      rescue StandardError
        false
      end

      # Refresh the mutex TTL — called after successful reap so the
      # key doesn't expire between cycles.
      def refresh_reaper_mutex
        interval = SidekiqUniqueJobs.config.reaper_interval
        ttl = interval + (interval * 0.02).ceil

        SidekiqUniqueJobs.redis do |conn|
          conn.call("SET", UNIQUE_REAPER, Process.pid.to_s, "EX", ttl.to_s)
        end
      rescue StandardError
        # non-critical
      end

      # Release mutex on shutdown so another process takes over immediately
      def release_reaper_mutex
        SidekiqUniqueJobs.redis do |conn|
          # Only delete if we own it
          owner = conn.call("GET", UNIQUE_REAPER)
          conn.call("DEL", UNIQUE_REAPER) if owner == Process.pid.to_s
        end
      rescue StandardError
        # non-critical
      end

      def start_reaper
        if reaper_disabled?
          log_info("Reaper is disabled (config.reaper=#{SidekiqUniqueJobs.config.reaper.inspect})")
          return
        end

        interval = SidekiqUniqueJobs.config.reaper_interval
        log_info("Starting reaper (interval=#{interval}s, count=#{SidekiqUniqueJobs.config.reaper_count})")
        @reaper_task = SidekiqUniqueJobs::TimerTask.new(
          run_now: false,
          execution_interval: interval,
        ) do
          reap(mutex: true)
          refresh_reaper_mutex
        end
        @reaper_task.execute
      end

      def reaper_disabled?
        reaper = SidekiqUniqueJobs.config.reaper
        [nil, false, :none].include?(reaper)
      end

      def start_metrics
        @metrics = LockMetrics.new

        SidekiqUniqueJobs.reflect do |on|
          on.unlock_failed { |item| @metrics.track(:unlock_failed, item) }
          on.execution_failed { |item, *| @metrics.track(:execution_failed, item) }
        end

        @flush_task = SidekiqUniqueJobs::TimerTask.new(run_now: false, execution_interval: 60) do
          @metrics.flush
        end
        @flush_task.execute
      end
    end
  end
end
