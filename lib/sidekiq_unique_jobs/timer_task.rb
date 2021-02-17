# frozen_string_literal: true

module SidekiqUniqueJobs
  # @see [Concurrent::TimerTask] https://www.rubydoc.info/gems/concurrent-ruby/Concurrent/TimerTask
  #
  class TimerTask < ::Concurrent::TimerTask
    private

    def ns_initialize(opts, &task)
      set_deref_options(opts)

      self.execution_interval = opts[:execution] || opts[:execution_interval] || EXECUTION_INTERVAL
      self.timeout_interval = opts[:timeout] || opts[:timeout_interval] || TIMEOUT_INTERVAL
      @run_now  = opts[:now] || opts[:run_now]
      @executor = Concurrent::RubySingleThreadExecutor.new
      @running  = Concurrent::AtomicBoolean.new(false)
      @task     = task
      @value    = nil

      self.observers = Concurrent::Collection::CopyOnNotifyObserverSet.new
    end

    def schedule_next_task(interval = execution_interval)
      exec_task = ->(completion) { execute_task(completion) }
      ScheduledTask.execute(interval, args: [Concurrent::Event.new], &exec_task)
      nil
    end

    # @!visibility private
    def execute_task(completion) # rubocop:disable Metrics/MethodLength
      return nil unless @running.true?

      timeout_task = -> { timeout_task(completion) }

      Concurrent::ScheduledTask.execute(
        timeout_interval,
        args: [completion],
        &timeout_task
      )
      @thread_completed = Concurrent::Event.new

      @value = @reason  = nil
      @executor.post do
        @value = @task.call(self)
      rescue Exception => ex # rubocop:disable Lint/RescueException
        @reason = ex
      ensure
        @thread_completed.set
      end

      @thread_completed.wait

      if completion.try?
        schedule_next_task
        time = Time.now
        observers.notify_observers do
          [time, value, @reason]
        end
      end
      nil
    end

    # @!visibility private
    def timeout_task(completion)
      return unless @running.true?
      return unless completion.try?

      @executor.kill
      @executor.wait_for_termination
      @executor = Concurrent::RubySingleThreadExecutor.new

      @thread_completed.set

      schedule_next_task
      observers.notify_observers(Time.now, nil, Concurrent::TimeoutError.new)
    end
  end
end
