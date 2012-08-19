require 'digest'

module SidekiqUniqueJobs
  module Middleware
    module Client
      class UniqueJobs
        HASH_KEY_EXPIRATION = 30 * 60

        def call(worker_class, item, queue)

          enabled = worker_class.get_sidekiq_options['unique']

          if enabled

            payload_hash = Digest::MD5.hexdigest(Sidekiq.dump_json(item['args']))

            unique = false

            Sidekiq.redis do |conn|

              conn.watch(payload_hash)

              if conn.get(payload_hash)
                conn.unwatch
              else
                expires_at = HASH_KEY_EXPIRATION
                expires_at = ((Time.at(item['at']) - Time.now.utc) * 24 * 60 * 60).to_i if item['at']

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