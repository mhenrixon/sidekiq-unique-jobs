require 'spec_helper'
require 'sidekiq/api'
require 'sidekiq/cli'
require 'sidekiq/worker'
require 'sidekiq_unique_jobs/server/middleware'

RSpec.describe SidekiqUniqueJobs::Server::Middleware do
  QUEUE ||= 'working'

  def digest_for(item)
    SidekiqUniqueJobs::UniqueArgs.digest(item)
  end

  before do
    Sidekiq.redis = REDIS
    Sidekiq.redis(&:flushdb)
  end

  describe '#call' do
    context 'when unique is disabled' do
      it 'does not use locking' do
        allow(subject).to receive(:unique_enabled?).and_return(false)
        expect(subject).not_to receive(:lock)
        args = [WhileExecutingJob, { 'class' => 'WhileExecutingJob' }, 'working', nil]
        subject.call(*args) {}
      end
    end

    context 'when unique is enabled' do
      it 'executes the lock' do
        allow(subject).to receive(:unique_enabled?).and_return(true)
        lock = instance_spy(SidekiqUniqueJobs::Lock::WhileExecuting)
        expect(lock).to receive(:send).with(:execute, instance_of(Proc)).and_yield
        expect(subject).to receive(:lock).and_return(lock)

        args = [WhileExecutingJob, { 'class' => 'WhileExecutingJob' }, 'working', nil]
        subject.call(*args) {}
      end
    end

    describe '#unlock' do
      it 'does not unlock mutexes it does not own' do
        jid = UntilExecutedJob.perform_async
        item = Sidekiq::Queue.new(QUEUE).find_job(jid).item
        Sidekiq.redis do |c|
          c.set(digest_for(item), 'NOT_DELETED')
        end

        subject.call(UntilExecutedJob.new, item, QUEUE) do
          Sidekiq.redis do |c|
            expect(c.get(digest_for(item))).to eq('NOT_DELETED')
          end
        end
      end
    end

    describe ':before_yield' do
      it 'removes the lock before yielding to the worker' do
        jid = UntilExecutingJob.perform_async
        item = Sidekiq::Queue.new(QUEUE).find_job(jid).item
        worker = UntilExecutingJob.new
        subject.call(worker, item, QUEUE) do
          Sidekiq.redis do |c|
            expect(c.ttl(digest_for(item))).to eq(-2) # key does not exist
          end
        end
      end
    end

    describe ':after_yield' do
      it 'removes the lock after yielding to the worker' do
        jid = UntilExecutedJob.perform_async
        item = Sidekiq::Queue.new(QUEUE).find_job(jid).item

        subject.call('UntilExecutedJob', item, QUEUE) do
          Sidekiq.redis do |c|
            expect(c.get(digest_for(item))).to eq jid
          end
        end
      end
    end
  end
end
