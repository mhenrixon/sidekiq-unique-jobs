require 'spec_helper'
require 'sidekiq/api'
require 'sidekiq/cli'
require 'sidekiq/worker'
require 'sidekiq_unique_jobs/server/middleware'

RSpec.describe SidekiqUniqueJobs::Server::Middleware do
  describe '#call' do
    describe 'unlock order' do
      QUEUE = 'unlock_ordering'.freeze unless defined?(QUEUE)

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

      before do
        Sidekiq.redis = REDIS
        Sidekiq.redis(&:flushdb)
      end

      describe '#unlock' do
        it 'does not unlock mutexes it does not own' do
          jid = AfterYieldOrderingWorker.perform_async
          item = Sidekiq::Queue.new(QUEUE).find_job(jid).item
          Sidekiq.redis do |c|
            c.set(get_payload(item), 'NOT_DELETED')
          end

          result = subject.call(AfterYieldOrderingWorker.new, item, QUEUE) do
            Sidekiq.redis do |c|
              c.get(get_payload(item))
            end
          end
          expect(result).to eq 'NOT_DELETED'
        end
      end

      describe ':before_yield' do
        it 'removes the lock before yielding to the worker' do
          jid = BeforeYieldOrderingWorker.perform_async
          item = Sidekiq::Queue.new(QUEUE).find_job(jid).item

          result = subject.call(BeforeYieldOrderingWorker.new, item, QUEUE) do
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

          result = subject.call(AfterYieldOrderingWorker.new, item, QUEUE) do
            Sidekiq.redis do |c|
              c.get(get_payload(item))
            end
          end

          expect(result).to eq jid
        end
      end
    end

    context 'unlock' do
      let(:items) { [AfterYieldWorker.new, { 'class' => 'testClass' }, 'fudge'] }

      it 'should unlock after yield when call succeeds' do
        expect(subject).to receive(:unlock)

        subject.call(*items) { true }
      end

      it 'should unlock after yield when call errors' do
        expect(subject).to receive(:unlock)

        expect { subject.call(*items) { fail } }.to raise_error(RuntimeError)
      end

      it 'should not unlock after yield on shutdown, but still raise error' do
        expect(subject).to_not receive(:unlock)

        expect { subject.call(*items) { fail Sidekiq::Shutdown } }.to raise_error(Sidekiq::Shutdown)
      end
    end

    context 'after unlock' do
      let(:worker) { AfterUnlockWorker.new }
      let(:items) { [worker, { 'class' => 'testClass' }, 'test'] }
      it 'should call the after_unlock hook if defined' do
        expect(subject).to receive(:unlock).and_call_original
        # expect(subject).to receive(:after_unlock_hook)
        expect(worker).to receive(:after_unlock)

        subject.call(*items) { true }
      end
    end
  end
end
