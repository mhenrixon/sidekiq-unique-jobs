require 'helper'
require 'sidekiq/worker'
require 'sidekiq-unique-jobs/middleware/server/unique_jobs'

class TestUnlockOrdering < MiniTest::Unit::TestCase
  QUEUE = 'unlock_ordering'

  class BeforeYieldOrderingWorker
    include Sidekiq::Worker

    sidekiq_options unique: true, unique_unlock_order: :before_yield, queue: QUEUE

    def perform
    end
  end

  class AfterYieldOrderingWorker
    include Sidekiq::Worker

    sidekiq_options unique: true, unique_unlock_order: :after_yield, queue: QUEUE

    def perform
    end
  end

  describe 'with real redis' do
    before do
      Sidekiq.redis = REDIS
      Sidekiq.redis { |c| c.flushdb }
      @middleware = SidekiqUniqueJobs::Middleware::Server::UniqueJobs.new
    end

    describe ':before_yield' do
      it 'removes the lock before yielding to the worker' do
        jid = BeforeYieldOrderingWorker.perform_async
        item = Sidekiq::Queue.new(QUEUE).find_job(jid).item

        result = @middleware.call(BeforeYieldOrderingWorker.new, item, QUEUE) do
          Sidekiq.redis do |c|
            c.get(SidekiqUniqueJobs::PayloadHelper.get_payload(item['class'], item['queue'], item['args']))
          end
        end

        assert_nil result
      end
    end

    describe ':after_yield' do
      it 'removes the lock after yielding to the worker' do
        jid = AfterYieldOrderingWorker.perform_async
        item = Sidekiq::Queue.new(QUEUE).find_job(jid).item

        result = @middleware.call(AfterYieldOrderingWorker.new, item, QUEUE) do
          Sidekiq.redis do |c|
            c.get(SidekiqUniqueJobs::PayloadHelper.get_payload(item['class'], item['queue'], item['args']))
          end
        end

        assert_equal '1', result
      end
    end
  end
end
