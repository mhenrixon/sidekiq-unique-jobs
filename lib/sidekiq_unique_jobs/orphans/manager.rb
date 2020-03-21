# frozen_string_literal: true

module SidekiqUniqueJobs
  module Orphans
    #
    # Manages the orphan reaper
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    module Manager
      module_function

      include SidekiqUniqueJobs::Connection
      include SidekiqUniqueJobs::Logging

      #
      # Starts a separate thread that periodically reaps orphans
      #
      #
      # @return [Concurrent::TimerTask] the task that was started
      #
      def start # rubocop:disable
        return if registered?
        return if disabled?

        with_logging_context do
          register_reaper_process
          log_info("Starting Reaper")
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
      def stop
        with_logging_context do
          log_info("Stopping Reaper")
          unregister_reaper_process
          task.shutdown
        end
      end

      #
      # The task that runs the reaper
      #
      #
      # @return [<type>] <description>
      #
      def task
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
      def timer_task_options
        { run_now: true,
          execution_interval: reaper_interval,
          timeout_interval: reaper_timeout }
      end

      #
      # @see SidekiqUniqueJobs::Config#reaper
      #
      def reaper
        SidekiqUniqueJobs.config.reaper
      end

      #
      # @see SidekiqUniqueJobs::Config#reaper_interval
      #
      def reaper_interval
        SidekiqUniqueJobs.config.reaper_interval
      end

      #
      # @see SidekiqUniqueJobs::Config#reaper_timeout
      #
      def reaper_timeout
        SidekiqUniqueJobs.config.reaper_timeout
      end

      #
      # A context to use for all log entries
      #
      #
      # @return [Hash] when logger responds to `:with_context`
      # @return [String] when logger does not responds to `:with_context`
      #
      def logging_context
        if logger_context_hash?
          { "uniquejobs" => "reaper" }
        else
          "uniquejobs=orphan-reaper"
        end
      end

      #
      # Checks if a reaper is already registered
      #
      #
      # @return [true, false]
      #
      def registered?
        redis { |conn| conn.get(UNIQUE_REAPER) }.to_i == 1
      end

      def disabled?
        reaper == :none
      end

      #
      # Writes a mutex key to redis
      #
      #
      # @return [void]
      #
      def register_reaper_process
        redis { |conn| conn.set(UNIQUE_REAPER, 1) }
      end

      #
      # Removes mutex key from redis
      #
      #
      # @return [void]
      #
      def unregister_reaper_process
        redis { |conn| conn.del(UNIQUE_REAPER) }
      end
    end
  end
end
