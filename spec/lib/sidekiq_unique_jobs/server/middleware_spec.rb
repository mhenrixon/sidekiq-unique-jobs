require 'spec_helper'
require 'sidekiq/api'
require 'sidekiq/cli'
require 'sidekiq/worker'
require 'sidekiq_unique_jobs/server/middleware'

RSpec.describe SidekiqUniqueJobs::Server::Middleware do
  QUEUE ||= 'unlock_ordering'

  def digest_for(item)
    SidekiqUniqueJobs::UniqueArgs.digest(item)
  end

  describe '#call' do
    describe 'unlock order' do
      before do
        Sidekiq.redis = REDIS
        Sidekiq.redis(&:flushdb)
      end

      describe '#unlock' do
        it 'does not unlock mutexes it does not own' do
          jid = UntilExecutedWorker.perform_async
          item = Sidekiq::Queue.new(QUEUE).find_job(jid).item
          Sidekiq.redis do |c|
            c.set(digest_for(item), 'NOT_DELETED')
          end

          subject.call(UntilExecutedWorker.new, item, QUEUE) do
            Sidekiq.redis do |c|
              expect(c.get(digest_for(item))).to eq('NOT_DELETED')
            end
          end
        end
      end

      describe ':before_yield' do
        it 'removes the lock before yielding to the worker' do
          jid = UntilExecutingWorker.perform_async
          item = Sidekiq::Queue.new(QUEUE).find_job(jid).item
          worker = UntilExecutingWorker.new
          subject.call(worker, item, QUEUE) do
            Sidekiq.redis do |c|
              expect(c.ttl(digest_for(item))).to eq(-2) # key does not exist
            end
          end
        end
      end

      describe ':after_yield' do
        it 'removes the lock after yielding to the worker' do
          jid = UntilExecutedWorker.perform_async
          item = Sidekiq::Queue.new(QUEUE).find_job(jid).item

          subject.call('UntilExecutedWorker', item, QUEUE) do
            Sidekiq.redis do |c|
              expect(c.get(digest_for(item))).to eq jid
            end
          end
        end
      end
    end

    context 'unlock' do
      let(:worker) { UntilExecutedWorker.new }

      before do
        jid  = UntilExecutedWorker.perform_async
        @item = Sidekiq::Queue.new('unlock_ordering').find_job(jid).item
      end

      it 'unlocks after yield when call succeeds' do
        expect(subject).to receive(:unlock)
        subject.call(worker, @item, 'unlock_ordering') { true }
      end

      it 'unlocks after yield when call errors' do
        expect(subject).to receive(:unlock)
        allow(subject).to receive(:after_yield_yield) { fail 'WAT!' }
        expect { subject.call(worker, @item, 'unlock_ordering') }
          .to raise_error
      end

      it 'should not unlock after yield on shutdown, but still raise error' do
        expect(subject).not_to receive(:unlock)
        allow(subject).to receive(:after_yield_yield) { fail Sidekiq::Shutdown }
        expect { subject.call(worker, @item, 'unlock_ordering') }
          .to raise_error(Sidekiq::Shutdown)
      end

      it 'calls after_unlock_hook if defined' do
        allow(subject).to receive(:unlock).and_call_original
        allow(subject).to receive(:after_unlock_hook).and_call_original

        expect(worker).to receive(:after_unlock)
        subject.call(worker, @item, 'unlock_ordering') { true }
      end
    end
  end
end
