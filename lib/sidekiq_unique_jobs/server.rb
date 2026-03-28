# frozen_string_literal: true

module SidekiqUniqueJobs
  # Server-side lifecycle management for sidekiq-unique-jobs.
  #
  # Handles startup (migration, metrics, reaper) and shutdown (flush, cleanup).
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class Server
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Script::Caller

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
      end

      # Run the reaper once (used by tests and manual invocation)
      #
      # @param conn [Redis, nil] optional connection
      # @return [Integer] number of stale digests removed
      def reap(conn = nil)
        if conn
          do_reap(conn)
        else
          SidekiqUniqueJobs.redis { |c| do_reap(c) }
        end
      end

      private

      def do_reap(conn)
        Script::Caller.call_script(
          :reap,
          conn,
          keys: [DIGESTS],
          argv: [SidekiqUniqueJobs.config.reaper_count],
        )
      end

      def start_reaper
        return if reaper_disabled?

        interval = SidekiqUniqueJobs.config.reaper_interval
        @reaper_task = SidekiqUniqueJobs::TimerTask.new(
          run_now: false,
          execution_interval: interval,
        ) { reap }
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
