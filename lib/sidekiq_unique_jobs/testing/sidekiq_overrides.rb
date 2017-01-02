require 'sidekiq/testing'

module Sidekiq
  module Worker
    module ClassMethods
      # Drain and run all jobs for this worker
      unless Sidekiq::Testing.respond_to?(:server_middleware)
        def drain
          while (job = jobs.shift)
            worker = new
            worker.jid = job['jid']
            worker.bid = job['bid'] if worker.respond_to?(:bid=)
            execute_job(worker, job['args'])
            unlock(job) if Sidekiq::Testing.fake?
          end
        end
      end

      # Pop out a single job and perform it
      unless Sidekiq::Testing.respond_to?(:server_middleware)
        def perform_one
          raise(EmptyQueueError, 'perform_one called with empty job queue') if jobs.empty?
          job = jobs.shift
          worker = new
          worker.jid = job['jid']
          worker.bid = job['bid'] if worker.respond_to?(:bid=)
          execute_job(worker, job['args'])
          unlock(job) if Sidekiq::Testing.fake?
        end
      end

      # Clear all jobs for this worker
      def clear
        jobs.each do |job|
          unlock(job) if Sidekiq::Testing.fake?
        end
        # if Sidekiq::VERSION >= '4'
        #   Queues.jobs[queue].clear
        # else
        jobs.clear
        # end
      end

      unless respond_to?(:execute_job)
        def execute_job(worker, args)
          worker.perform(*args)
        end
      end

      def unlock(job)
        SidekiqUniqueJobs::Unlockable.unlock(job)
      end
    end

    module Overrides
      def self.included(base)
        base.extend Testing
        base.class_eval do
          class << self
            alias_method :clear_all_orig, :clear_all
            alias_method :clear_all, :clear_all_ext
          end
        end
      end

      module Testing
        def clear_all_ext
          SidekiqUniqueJobs::Util.del('*', 1000, false) unless SidekiqUniqueJobs.mocked?
          clear_all_orig
        end
      end
    end

    include Overrides
  end
end
