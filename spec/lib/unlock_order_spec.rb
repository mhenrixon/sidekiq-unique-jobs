require 'spec_helper'
require 'sidekiq/api'
require 'sidekiq/worker'
require 'sidekiq_unique_jobs/server/middleware'
require 'sidekiq_unique_jobs/exception'

describe 'Unlock order' do
  QUEUE = 'unlock_ordering'

  def get_payload(item)
    SidekiqUniqueJobs.get_payload(
      item['class'], item['queue'], item['args'])
  end

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

  class RunLockOrderingWorker
    include Sidekiq::Worker

    sidekiq_options unique: true, unique_unlock_order: :run_lock, queue: QUEUE
    def perform
    end
  end

  class RunLockSpinningWorker
    include Sidekiq::Worker

    sidekiq_options unique: true,
                    unique_unlock_order: :run_lock,
                    queue: QUEUE,
                    run_lock_retries: 10,
                    run_lock_retry_interval: 0,
                    reschedule_on_lock_fail: true
    def perform
    end
  end

  describe 'with real redis' do
    before do
      Sidekiq.redis = REDIS
      Sidekiq.redis(&:flushdb)
      @middleware = SidekiqUniqueJobs::Server::Middleware.new
    end

    describe '#unlock' do
      it 'does not unlock mutexes it does not own' do
        jid = AfterYieldOrderingWorker.perform_async
        item = Sidekiq::Queue.new(QUEUE).find_job(jid).item
        Sidekiq.redis do |c|
          c.set(get_payload(item), 'NOT_DELETED')
        end

        result = @middleware.call(AfterYieldOrderingWorker.new, item, QUEUE) do
          Sidekiq.redis do |c|
            c.get(get_payload(item))
          end
        end
        expect(result).to eq 'NOT_DELETED'
      end
    end

    describe ':run_lock' do
      it 'should acquire run_lock before yielding if :run_lock is set' do
        jid = RunLockOrderingWorker.perform_async
        item = Sidekiq::Queue.new(QUEUE).find_job(jid).item
        result = @middleware.call(RunLockOrderingWorker.new, item, QUEUE) do
          Sidekiq.redis do |c|
            c.get("#{get_payload(item)}:run")
          end
        end
        expect(result).to eq jid
      end

      it 'should raise if it could not acquire run_lock' do
        jid = RunLockOrderingWorker.perform_async
        item = Sidekiq::Queue.new(QUEUE).find_job(jid).item
        Sidekiq.redis do |c|
          c.set("#{get_payload(item)}:run", 'LOCKED_OUT')
        end
        expect do
          @middleware.call(RunLockOrderingWorker.new, item, QUEUE) do
            true
          end
        end.to raise_error SidekiqUniqueJobs::RunLockFailedError
      end

      it 'should spin_lock is run_lock_retries are set' do
        jid = RunLockSpinningWorker.perform_async
        item = Sidekiq::Queue.new(QUEUE).find_job(jid).item
        Sidekiq.redis do |c|
          c.set("#{get_payload(item)}:run", 'LOCKED_OUT')
        end
        expect(Sidekiq).to receive(:redis).exactly(11).times.and_call_original
        @middleware.call(RunLockSpinningWorker.new, item, QUEUE) do
          true
        end
      end

      it 'should reschedule if reschedule on lock fail is set' do
        jid = RunLockSpinningWorker.perform_async
        item = Sidekiq::Queue.new(QUEUE).find_job(jid).item
        Sidekiq.redis do |c|
          c.set("#{get_payload(item)}:run", 'LOCKED_OUT')
        end
        expect_any_instance_of(Sidekiq::Client).to receive(:raw_push).with([item])
        @middleware.call(RunLockSpinningWorker.new, item, QUEUE) do
          true
        end
      end
    end

    describe ':before_yield' do
      it 'removes the lock before yielding to the worker' do
        jid = BeforeYieldOrderingWorker.perform_async
        item = Sidekiq::Queue.new(QUEUE).find_job(jid).item
        result = @middleware.call(BeforeYieldOrderingWorker.new, item, QUEUE) do
          Sidekiq.redis do |c|
            c.get(get_payload(item))
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
            c.get(get_payload(item))
          end
        end

        expect(result).to eq jid
      end
    end
  end
end
