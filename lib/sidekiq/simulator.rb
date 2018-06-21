# frozen_string_literal: true

require 'sidekiq/cli'
require 'sidekiq/launcher'

require 'sidekiq_unique_jobs/timeout'

module Sidekiq
  class Simulator
    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Timeout

    attr_reader :queues, :launcher

    def self.process_queue(queue)
      new(queue).process_queue { yield }
    end

    def initialize(queue)
      @queues = Array(queue).uniq
      @launcher = Sidekiq::Launcher.new(sidekiq_options(queues))
    end

    def process_queue
      run_launcher
      yield
    ensure
      terminate_launcher
    end

    private

    def run_launcher
      run_launcher!
    rescue Timeout::Error => exception
      log_warn('Timeout while starting Sidekiq')
      log_warn(exception)
    end

    def run_launcher!
      using_timeout(15) do
        launcher.run
        sleep 0.001 until alive?
      end
    end

    def terminate_launcher
      launcher.stop
    end

    def alive?
      launcher.manager.workers.any?
    end

    def stopped?
      !alive?
    end

    def sidekiq_options(queues = [])
      { queues: queues,
        concurrency: 3,
        timeout: 3,
        verbose: false,
        logfile: './tmp/sidekiq.log' }
    end
  end
end
