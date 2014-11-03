require 'digest'

module SidekiqUniqueJobs
  module Middleware
    module Server
      class UniqueJobs
        attr_reader :unlock_order, :redis_pool

        def call(worker, item, _queue, redis_pool = nil)
          @redis_pool = redis_pool

          decide_unlock_order(worker.class)
          lock_key = payload_hash(item)
          unlocked = before_yield? ? unlock(lock_key).inspect : 0

          yield
        ensure
          if after_yield? || !defined? unlocked || unlocked != 1
            unlock(lock_key)
          end
        end

        def decide_unlock_order(klass)
          @unlock_order = if unlock_order_configured?(klass)
                            klass.get_sidekiq_options['unique_unlock_order']
                          else
                            default_unlock_order
                          end
        end

        def unlock_order_configured?(klass)
          klass.respond_to?(:get_sidekiq_options) &&
            !klass.get_sidekiq_options['unique_unlock_order'].nil?
        end

        def default_unlock_order
          SidekiqUniqueJobs.config.default_unlock_order
        end

        def before_yield?
          unlock_order == :before_yield
        end

        def after_yield?
          unlock_order == :after_yield
        end

        protected

        def payload_hash(item)
          SidekiqUniqueJobs::PayloadHelper.get_payload(item['class'], item['queue'], item['args'])
        end

        def unlock(payload_hash)
          connector.del(payload_hash)
        end

        def logger
          Sidekiq.logger
        end

        def connector
          return SidekiqUniqueJobs.redis_mock { |conn| conn } if SidekiqUniqueJobs.config.testing_enabled?
          return redis_pool.with { |conn| conn } if redis_pool
          Sidekiq.redis { |conn| conn }
        end
      end
    end
  end
end
