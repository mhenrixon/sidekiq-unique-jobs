require 'sidekiq/launcher'
require 'timeout'

module Sidekiq
  class Simulator
    attr_reader :queues, :launcher

    def self.process_queue(queue)
      new(queue).process_queue { yield }
    end

    def initialize(queue)
      @queues = [queue].flatten.uniq
      @launcher = Sidekiq::Launcher.new(sidekiq_options(queues))
    end

    def process_queue
      run_launcher { yield }
    ensure
      terminate_launcher
    end

    private

    def run_launcher
      using_timeout(15) do
        launcher.run
        sleep 0.001 until alive?
      end
    rescue Timeout::Error => e
      logger.warn { "Timeout while running #{__method__}" }
      logger.warn { e }
    ensure
      yield
    end

    def terminate_launcher
      if launcher.respond_to?(:alive?)
        launcher.terminate # Better to be fast than graceful for our purposes
      else
        launcher.stop # New sidekiq works better
      end
    end

    def alive?
      if launcher.respond_to?(:alive?)
        launcher.alive?
      else
        launcher.manager.workers.size > 0
      end
    end

    def stopped?
      !alive?
    end

    def using_timeout(value)
      Timeout.timeout(value) do
        yield
      end
    end

    def sidekiq_options(queues = [])
      { queues: queues,
        concurrency: 3,
        timeout: 3,
        verbose: false,
        logfile: './tmp/sidekiq.log' }
    end

    def logger
      @logger ||= Sidekiq.logger
    end
  end
end
