# frozen_string_literal: true

module SidekiqUniqueJobs
  module Orphans
    #
    # Manages the orphan reaper
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class Manager
      include SidekiqUniqueJobs::Connection
      include SidekiqUniqueJobs::Logging

      #
      # Starts a separate thread that periodically reaps orphans
      #
      #
      # @return [Concurrent::TimerTask] the task that was started
      #
      def self.start
        with_logging_context do
          logger.info("Starting Reaper")
          task.add_observer(Observer.new)
          task.execute
          task
        end
      end

      #
      # Stops the thread that reaps orphans
      #
      #
      # @return [Boolean]
      #
      def self.stop
        with_logging_context do
          logger.info("Stopping Reaper")
          task.shutdown
        end
      end

      #
      # The task that runs the reaper
      #
      #
      # @return [<type>] <description>
      #
      def self.task
        @task ||= Concurrent::TimerTask.new(timer_task_options) do
          with_logging_context do
            redis do |conn|
              Orphans::Reaper.call(conn)
            end
          end
        end
      end

      #
      # Arguments passed on to the timer task
      #
      #
      # @return [Hash]
      #
      def self.timer_task_options
        { run_now: true,
          execution_interval: reaper_interval,
          timeout_interval: reaper_timeout }
      end

      #
      # @see SidekiqUniqueJobs::Config#reaper_interval
      #
      def self.reaper_interval
        SidekiqUniqueJobs.config.reaper_interval
      end

      #
      # @see SidekiqUniqueJobs::Config#reaper_timeout
      #
      def self.reaper_timeout
        SidekiqUniqueJobs.config.reaper_timeout
      end

      #
      # A context to use for all log entries
      #
      #
      # @return [Hash] when logger responds to `:with_context`
      # @return [String] when logger does not responds to `:with_context`
      #
      def self.logging_context
        if logger.respond_to?(:with_context)
          { "uniquejobs" => "reaper" }
        else
          "uniquejobs=orphan-reaper"
        end
      end
    end
  end
end
