require 'digest'

module SidekiqUniqueJobs
  module Middleware
    module Client
      class UniqueJobs
        def call(worker_class, item, queue)

          enabled = worker_class.get_sidekiq_options['unique']
          unique_job_expiration = worker_class.get_sidekiq_options['unique_job_expiration']

          if enabled

            payload_hash = SidekiqUniqueJobs::PayloadHelper.get_payload(item['class'], item['queue'], item['args'])

            unique = false

            Sidekiq.redis do |conn|

              conn.watch(payload_hash)

              if conn.get(payload_hash)
                conn.unwatch
              else
                expires_at = unique_job_expiration || SidekiqUniqueJobs::Config.default_expiration
                expires_at = ((Time.at(item['at']) - Time.now.utc) + expires_at).to_i if item['at']

                unique = conn.multi do
                  conn.setex(payload_hash, expires_at, 1)
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
