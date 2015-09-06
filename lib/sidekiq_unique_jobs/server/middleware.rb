require 'digest'
require 'forwardable'
require 'sidekiq_unique_jobs/server/extensions'

module SidekiqUniqueJobs
  module Server
    class Middleware
      extend Forwardable
      def_delegators :SidekiqUniqueJobs, :connection, :payload_hash, :synchronize
      def_delegators :'SidekiqUniqueJobs.config', :default_unlock_order,
                     :default_reschedule_on_lock_fail
      def_delegators :Sidekiq, :logger

      include Extensions

      attr_reader :redis_pool,
                  :worker,
                  :options

      def call(worker, item, _queue, redis_pool = nil, &blk)
        @worker = worker
        @redis_pool = redis_pool
        setup_options(worker.class)
        send("#{unlock_order}_call", item, &blk)
      end

      def setup_options(klass)
        @options = {}
        options.merge!(klass.get_sidekiq_options) if klass.respond_to?(:get_sidekiq_options)
      end

      def before_yield_call(item)
        unlock(payload_hash(item), item)
        yield
      end

      def after_yield_call(item)
        operative = true
        yield
      rescue Sidekiq::Shutdown
        operative = false
        raise
      ensure
        unlock(payload_hash(item), item) if operative
      end

      def run_lock_call(item)
        lock_key = payload_hash(item)
        connection do |con|
          synchronize(lock_key, con, item.dup.merge(options)) do
            unlock(lock_key, item)
            yield
          end
        end
      rescue SidekiqUniqueJobs::RunLockFailed
        return reschedule(item) if reschedule_on_lock_fail
        raise
      end

      def unlock_order
        return :never unless options['unique']
        options['unique_unlock_order'] || default_unlock_order
      end

      def never_call(*)
        yield if block_given?
      end

      def reschedule_on_lock_fail
        options['reschedule_on_lock_fail'] || default_reschedule_on_lock_fail
      end

      protected

      def unlock(lock_key, item)
        connection do |con|
          con.eval(remove_on_match, keys: [lock_key], argv: [item['jid']])
        end
        after_unlock_hook
      end

      def after_unlock_hook
        worker.after_unlock if worker.respond_to?(:after_unlock)
      end

      def reschedule(item)
        Sidekiq::Client.new(redis_pool).raw_push([item])
      end
    end
  end
end
