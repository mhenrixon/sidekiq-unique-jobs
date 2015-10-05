require 'sidekiq_unique_jobs/testing/sidekiq_overrides'

module SidekiqUniqueJobs
  module Client
    class Middleware
      alias_method :call_real, :call
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
    end
  end

  class Testing
    def mocking!
      require 'sidekiq_unique_jobs/testing/mocking'
    end
  end
end
