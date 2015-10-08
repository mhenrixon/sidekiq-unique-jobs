require 'sidekiq/testing'

module Sidekiq
  module Worker
    module ClassMethods
      include SidekiqUniqueJobs::Unlockable

      # Drain and run all jobs for this worker
      def drain
        while (job = jobs.shift)
          worker = new
          worker.jid = job['jid']
          worker.bid = job['bid'] if worker.respond_to?(:bid=)
          execute_job(worker, job['args'])
          unlock(job['unique_digest'], job['jid']) if Sidekiq::Testing.fake?
        end
      end

      # Pop out a single job and perform it
      def perform_one
        fail(EmptyQueueError, 'perform_one called with empty job queue') if jobs.empty?
        job = jobs.shift
        worker = new
        worker.jid = job['jid']
        worker.bid = job['bid'] if worker.respond_to?(:bid=)
        execute_job(worker, job['args'])
        unlock(job['unique_digest'], job['jid']) if Sidekiq::Testing.fake?
      end

      # Clear all jobs for this worker
      def clear
        jobs.each do |job|
          unlock(job['unique_digest'], job['jid']) if Sidekiq::Testing.fake?
        end
        jobs.clear
      end

      def execute_job(worker, args)
        worker.perform(*args)
      end unless respond_to?(:execute_job)
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
          Sidekiq.redis do |c|
            unique_keys = c.keys("#{SidekiqUniqueJobs.config.unique_prefix}:*")
            c.del(*unique_keys) unless unique_keys.empty?
          end
          clear_all_orig
        end
      end
    end

    include Overrides
  end
end
