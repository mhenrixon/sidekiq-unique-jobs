require 'digest'
require 'sidekiq_unique_jobs/connectors'
require 'sidekiq_unique_jobs/server/extensions'

module SidekiqUniqueJobs
  module Server
    class Middleware
      include Extensions

      attr_reader :unlock_order,
                  :redis_pool,
                  :reschedule_on_lock_fail,
                  :run_lock_retries,
                  :run_lock_retry_interval

      def call(worker, item, _queue, redis_pool = nil, &blk)
        @redis_pool = redis_pool
        setup_options(worker.class)
        send("#{unlock_order}_call", item, &blk)
      end

      # rubocop:disable MethodLength
      def run_lock_call(item)
        lock_key = payload_hash(item)
        run_lock = try_acquire_run_lock(lock_key, item)
        if run_lock
          unlock(lock_key, item)
          yield
        else
          if reschedule_on_lock_fail
            reschedule(item)
          else # Not sure if we want to raise?
            fail SidekiqUniqueJobs::RunLockFailedError
          end
        end
      ensure
        unlock_run(lock_key, item) if run_lock
      end
      # rubocop:enable MethodLength

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

      def never_call(*)
        yield if block_given?
      end

      def options
        @options ||= {}
      end

      def setup_options(klass)
        @options = klass.get_sidekiq_options if klass.respond_to?(:get_sidekiq_options)
      end

      def unlock_order
        if !options[:unique]
          :never
        else
          options['unique_unlock_order'] || SidekiqUniqueJobs.config.default_unlock_order
        end
      end

      def reschedule_on_lock_fail
        options['reschedule_on_lock_fail'] || SidekiqUniqueJobs.config.default_reschedule_on_lock_fail
      end

      def run_lock_retries
        options['run_lock_retries'] || SidekiqUniqueJobs.config.default_run_lock_retries
      end

      def run_lock_retry_interval
        options['run_lock_retry_interval'] || SidekiqUniqueJobs.config.default_run_lock_retry_interval
      end

      def run_lock_expire
        options['run_lock_expire'] || SidekiqUniqueJobs.config.default_run_lock_expire
      end

      protected

      def unlock(lock_key, item)
        connection do |con|
          con.eval(remove_on_match, keys: [lock_key], argv: [item['jid']])
        end
      end

      def payload_hash(item)
        SidekiqUniqueJobs.get_payload(item['class'], item['queue'], item['args'])
      end

      def logger
        Sidekiq.logger
      end

      def connection(&block)
        SidekiqUniqueJobs::Connectors.connection(redis_pool, &block)
      end

      def unlock_run(lock_key, item)
        connection do |con|
          con.eval(remove_on_match, keys: ["#{lock_key}:run"], argv: [item['jid']])
        end
      end

      def reschedule(item)
        Sidekiq::Client.new(redis_pool).raw_push([item])
      end

      # rubocop:disable HandleExceptions
      def try_acquire_run_lock(lock_key, item)
        status = begin
          (run_lock_retries + 1).times do
            status = connection do |con|
              con.set("#{lock_key}:run", item['jid'], nx: true, ex: run_lock_expire)
            end
            break if status
            sleep(run_lock_retry_interval)
          end
          status
        rescue Redis::ConnectionError, Redis::TimeoutError
          # Don't say I didn't warn you about spinlocks
        end
      end
      # rubocop:enable HandleExceptions
    end
  end
end
