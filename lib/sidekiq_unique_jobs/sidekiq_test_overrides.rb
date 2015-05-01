require 'sidekiq/testing'

module Sidekiq
  module Worker
    module ClassMethods
      module Overrides
        def self.included(base)
          base.class_eval do
            alias_method :execute_job_orig, :execute_job
            alias_method :execute_job, :execute_job_ext

            alias_method :clear_orig, :clear
            alias_method :clear, :clear_ext
          end
        end

        def execute_job_ext(worker, args)
          execute_job_orig(worker, args)
          payload_hash = SidekiqUniqueJobs::PayloadHelper.get_payload(
            worker.class.name,
            get_sidekiq_options['queue'],
            args
          )
          Sidekiq.redis { |conn| conn.del(payload_hash) }
        end
      end

      def clear_ext
        payload_hashes = jobs.map { |job| job['unique_hash'] }
        clear_orig
        return if payload_hashes.empty?

        Sidekiq.redis { |conn| conn.del(*payload_hashes) }
      end

      include Overrides
    end
  end
end

module Sidekiq
  module Worker
    module Overrides
      def self.included(base)
        base.extend ClassMethods

        base.instance_eval do
          class << self
            alias_method :clear_all_orig, :clear_all
            alias_method :clear_all, :clear_all_ext
          end
        end
      end

      module ClassMethods
        def clear_all_ext
          clear_all_orig
          unique_prefix = SidekiqUniqueJobs.config.unique_prefix
          unique_keys = Sidekiq.redis { |conn| conn.keys("#{unique_prefix}*") }
          return if unique_keys.empty?

          Sidekiq.redis { |conn| conn.del(*unique_keys) }
        end
      end
    end

    include Overrides
  end
end
