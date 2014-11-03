require 'spec_helper'
require 'sidekiq/api'
require 'sidekiq/worker'
require 'sidekiq_unique_jobs/middleware/server/unique_jobs'

describe 'Unlock order' do
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
      Sidekiq.redis(&:flushdb)
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

        expect(result).to eq nil
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

        expect(result).to eq '1'
      end
    end
  end
end
