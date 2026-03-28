# frozen_string_literal: true

module SidekiqUniqueJobs
  # The unique sidekiq middleware for the server processor
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class Server
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

        config.death_handlers << death_handler
      end

      def start
        SidekiqUniqueJobs::UpgradeLocks.call
        start_metrics
        SidekiqUniqueJobs::Orphans::Manager.start
        SidekiqUniqueJobs::Orphans::ReaperResurrector.start
      end

      def stop
        @flush_task&.shutdown
        @metrics&.flush
        SidekiqUniqueJobs::Orphans::Manager.stop
      end

      def death_handler
        DEATH_HANDLER
      end

      private

      def start_metrics
        @metrics = LockMetrics.new

        SidekiqUniqueJobs.reflect do |on|
          on.locked { |item| @metrics.track(:locked, item) }
          on.lock_failed { |item| @metrics.track(:lock_failed, item) }
          on.unlocked { |item| @metrics.track(:unlocked, item) }
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
