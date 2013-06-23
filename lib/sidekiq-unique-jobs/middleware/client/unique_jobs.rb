require 'digest'

module SidekiqUniqueJobs
  module Middleware
    module Client
      class UniqueJobs
        def call(worker_class, item, queue)

          klass = worker_class_constantize(worker_class)

          enabled = klass.get_sidekiq_options['unique'] || item['unique']
          unique_job_expiration = klass.get_sidekiq_options['unique_job_expiration']

          if enabled

            payload_hash = SidekiqUniqueJobs::PayloadHelper.get_payload(item['class'], item['queue'], item['args'])

            unique = false

            Sidekiq.redis do |conn|

              conn.watch(payload_hash)

              if conn.get(payload_hash).to_i == 1 || 
                (conn.get(payload_hash).to_i == 2 && item['at'])
                # if the job is already queued, or is already scheduled and 
                # we're trying to schedule again, abort 
                conn.unwatch
              else
                # if the job was previously scheduled and is now being queued,
                # or we've never seen it before
                expires_at = unique_job_expiration || SidekiqUniqueJobs::Config.default_expiration
                expires_at = ((Time.at(item['at']) - Time.now.utc) + expires_at).to_i if item['at']

                unique = conn.multi do
                  # set value of 2 for scheduled jobs, 1 for queued jobs.
                  conn.setex(payload_hash, expires_at, item['at'] ? 2 : 1)
                end
              end
            end
            yield if unique
          else
            yield
          end
        end

        protected

        # Attempt to constantize a string worker_class argument, always 
        # failing back to the original argument.
        # Duplicates Rails' String.constantize logic for non-Rails cases.
        def worker_class_constantize(worker_class)
          if worker_class.is_a?(String)
            if worker_class.respond_to?(:constantize)
              worker_class.constantize
            else
              # duplicated logic from Rails 3.2.13 ActiveSupport::Inflector
              # https://github.com/rails/rails/blob/9e0b3fc7cfba43af55377488f991348e2de24515/activesupport/lib/active_support/inflector/methods.rb#L213
              names = worker_class.split('::')
              names.shift if names.empty? || names.first.empty?
              constant = Object
              names.each do |name|
                constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
              end
              constant
            end
          else
            worker_class
          end
        rescue
          worker_class
        end

      end
    end
  end
end
