require 'sidekiq_unique_jobs/testing/sidekiq_overrides'

module SidekiqUniqueJobs
  module Client
    class Middleware
      alias_method :call_real, :call
      alias_method :unique_for_connection_real?, :unique_for_connection?

      def call(worker_class, item, queue, redis_pool = nil)
        worker_class = SidekiqUniqueJobs.worker_class_constantize(worker_class)

        if Sidekiq::Testing.inline?
          _server.call(worker_class.new, item, queue, redis_pool) do
            call_real(worker_class, item, queue, redis_pool) do
              yield
            end
          end
        else
          call_real(worker_class, item, queue, redis_pool) do
            yield
          end
        end
      end

      def _server
        SidekiqUniqueJobs::Server::Middleware.new
      end

      def unique_for_connection?
        return unique_for_connection_real? unless Sidekiq::Testing.fake?
        return true if worker_class.jobs.empty?

        worker_class.jobs.find do |job|
          item['unique_hash'] == job['unique_hash']
        end.nil?
      end
    end
  end

  module Server
    class Middleware
      alias_method :unlock_real, :unlock

      def unlock(lock_key, item)
        return unlock_real(lock_key, item) unless SidekiqUniqueJobs.config.mocking?

        connection do |con|
          con.watch(lock_key)
          return con.unwatch unless con.get(lock_key) == item['jid']

          con.multi { con.del(lock_key) }
        end
      end
    end
  end

  class Testing
    def mocking!
      require 'sidekiq_unique_jobs/testing/mocking'
    end
  end
end
