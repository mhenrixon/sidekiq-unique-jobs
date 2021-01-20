# frozen_string_literal: true

module SidekiqUniqueJobs
  module Orphans
    #
    # Manages the orphan reaper
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    module Manager
      module_function

      DRIFT_FACTOR = 0.02
      REAPERS      = [:ruby, :lua].freeze

      include SidekiqUniqueJobs::Connection
      include SidekiqUniqueJobs::Logging

      #
      # Starts a separate thread that periodically reaps orphans
      #
      #
      # @return [Concurrent::TimerTask] the task that was started
      #
      def start # rubocop:disable
        return if disabled?
        return if registered?

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
        return if disabled?
        return if unregistered?

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
        @task ||= Concurrent::TimerTask.new(timer_task_options, &task_body)
      end

      # @private
      def task_body
        @task_body ||= lambda do
          with_logging_context do
            redis do |conn|
              refresh_reaper_mutex
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
      # Checks if a reaper is registered
      #
      #
      # @return [true, false]
      #
      def registered?
        redis do |conn|
          conn.get(UNIQUE_REAPER).to_i + drift_reaper_interval > current_timestamp
        end
      end

      #
      # Checks if that reapers are not registerd
      #
      # @see registered?
      #
      # @return [true, false]
      #
      def unregistered?
        !registered?
      end

      #
      # Checks if reaping is disabled
      #
      # @see enabled?
      #
      # @return [true, false]
      #
      def disabled?
        !enabled?
      end

      #
      # Checks if reaping is enabled
      #
      # @return [true, false]
      #
      def enabled?
        REAPERS.include?(reaper)
      end

      #
      # Writes a mutex key to redis
      #
      #
      # @return [void]
      #
      def register_reaper_process
        redis { |conn| conn.set(UNIQUE_REAPER, current_timestamp, nx: true, ex: drift_reaper_interval) }
      end

      #
      # Updates mutex key
      #
      #
      # @return [void]
      #
      def refresh_reaper_mutex
        redis { |conn| conn.set(UNIQUE_REAPER, current_timestamp, ex: drift_reaper_interval) }
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

      def drift_reaper_interval
        reaper_interval + (reaper_interval * DRIFT_FACTOR).to_i
      end

      def current_timestamp
        Time.now.to_i
      end
    end
  end
end
