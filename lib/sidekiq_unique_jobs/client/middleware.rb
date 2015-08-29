require 'sidekiq_unique_jobs/server/middleware'

module SidekiqUniqueJobs
  module Client
    class Middleware
      SCHEDULED = 'scheduled'.freeze
      extend Forwardable
      def_delegators :SidekiqUniqueJobs, :connection, :config, :payload_hash
      def_delegators :config, :unique_storage_method
      def_delegators :Sidekiq, :logger

      def call(worker_class, item, queue, redis_pool = nil)
        @worker_class = SidekiqUniqueJobs.worker_class_constantize(worker_class)
        @item = item
        @queue = queue
        @redis_pool = redis_pool

        return yield unless unique_enabled?
        item['unique_hash'] = payload_hash(item)
        unless unique_for_connection?
          logger.warn "payload is not unique #{item}" if log_duplicate_payload?
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
        send("#{unique_storage_method}_unique_for?")
      end

      def old_unique_for?
        item['at'] ? unique_schedule_old : unique_enqueue_old
      end

      def unique_enqueue_old
        connection do |conn|
          conn.watch(payload_hash(item))
          lock_val = conn.get(payload_hash(item))
          if !lock_val || lock_val[0..8] == SCHEDULED
            conn.multi do
              conn.setex(payload_hash(item), expires_at, item['jid'])
            end
          else
            conn.unwatch
            false
          end
        end
      end

      def unique_schedule_old
        connection do |conn|
          conn.watch(payload_hash(item))
          if expires_at < 0 || conn.get(payload_hash(item))
            conn.unwatch
            false
          else
            conn.setex(payload_hash(item), expires_at, "scheduled-#{item['jid']}")
          end
        end
      end

      def new_unique_for?
        item['at'] ? unique_schedule : unique_enqueue
      end

      def unique_schedule
        connection do |conn|
          conn.set(payload_hash(item), "scheduled-#{item['jid']}", nx: true, ex: expires_at)
        end
      end

      def unique_enqueue
        connection do |conn|
          conn.eval(lock_queue_script, keys: [payload_hash(item)], argv: [expires_at, item['jid']])
        end
      end

      def expires_at
        # if the job was previously scheduled and is now being queued,
        # or we've never seen it before
        ex = unique_job_expiration || config.default_expiration
        ex = ((Time.at(item['at']) - Time.now.utc) + ex).to_i if item['at']
        ex
      end

      def unique_job_expiration
        worker_class.get_sidekiq_options['unique_job_expiration']
      end

      def lock_queue_script
        <<-LUA
          local ret = redis.call('GET', KEYS[1])
          if not ret or string.sub(ret, 1, 9) == 'scheduled' then
            return redis.call('SETEX', KEYS[1], ARGV[1], ARGV[2])
          end
        LUA
      end
    end
  end
end
