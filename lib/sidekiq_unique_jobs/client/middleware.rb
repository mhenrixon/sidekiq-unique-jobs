require 'sidekiq_unique_jobs/server/middleware'
require 'sidekiq_unique_jobs/connectors'

module SidekiqUniqueJobs
  module Client
    class Middleware
      def call(worker_class, item, queue, redis_pool = nil)
        @worker_class = SidekiqUniqueJobs.worker_class_constantize(worker_class)
        @item = item
        @queue = queue
        @redis_pool = redis_pool

        return yield unless unique_enabled?
        item['unique_hash'] = payload_hash
        unless unique_for_connection?
          Sidekiq.logger.warn "payload is not unique #{item}" if log_duplicate_payload?
          return
        end

        yield
      end

      private

      attr_reader :item, :worker_class, :redis_pool, :queue

      def unique_enabled?
        worker_class.get_sidekiq_options['unique'] || item['unique']
      end

      def log_duplicate_payload?
        worker_class.get_sidekiq_options['log_duplicate_payload'] || item['log_duplicate_payload']
      end

      def unique_for_connection?
        send("#{storage_method}_unique_for?")
      end

      def storage_method
        SidekiqUniqueJobs.config.unique_storage_method
      end

      # rubocop:disable MethodLength
      def old_unique_for?
        connection do |conn|
          conn.watch(payload_hash)
          pid = conn.get(payload_hash).to_i
          if pid == 1 || (pid == 2 && item['at'])
            conn.unwatch
            nil
          else
            conn.multi do
              if expires_at > 0
                conn.setex(payload_hash, expires_at, item['jid'])
              else
                conn.del(payload_hash)
              end
            end
          end
        end
      end
      # rubocop:enable MethodLength

      def new_unique_for?
        connection do |conn|
          return conn.set(payload_hash, item['jid'], nx: true, ex: expires_at) || conn.get(payload_hash) == item['jid']
        end
      end

      def expires_at
        # if the job was previously scheduled and is now being queued,
        # or we've never seen it before
        ex = unique_job_expiration || SidekiqUniqueJobs.config.default_expiration
        ex = ((Time.at(item['at']) - Time.now.utc) + ex).to_i if item['at']
        ex
      end

      def connection(&block)
        SidekiqUniqueJobs::Connectors.connection(redis_pool, &block)
      end

      def payload_hash
        SidekiqUniqueJobs.get_payload(item['class'], item['queue'], item['args'])
      end

      def unique_job_expiration
        worker_class.get_sidekiq_options['unique_job_expiration']
      end
    end
  end
end
