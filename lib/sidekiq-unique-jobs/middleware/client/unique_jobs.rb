require 'digest'

module SidekiqUniqueJobs
  module Middleware
    module Client
      class UniqueJobs
        def call(worker_class, item, queue)

          enabled = worker_class.get_sidekiq_options['unique'] || item['unique']
          unique_job_expiration = worker_class.get_sidekiq_options['unique_job_expiration']

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

      end
    end
  end
end
