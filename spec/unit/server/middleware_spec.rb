# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/api'
require 'sidekiq/cli'
require 'sidekiq/worker'
require 'sidekiq_unique_jobs/server/middleware'

RSpec.describe SidekiqUniqueJobs::Server::Middleware, redis: :redis, redis_db: 9 do
  let(:middleware) { SidekiqUniqueJobs::Server::Middleware.new }

  let(:queue) { 'working' }

  describe '#call' do
    subject { middleware.call(*args) {} }

    let(:args) { [WhileExecutingJob, { 'class' => 'WhileExecutingJob' }, 'working', nil] }

    context 'when unique is disabled' do
      before do
        allow(middleware).to receive(:unique_disabled?).and_return(true)
      end

      it 'does not use locking' do
        expect(middleware).not_to receive(:lock)
        subject
      end
    end

    context 'when unique is enabled' do
      let(:lock) { instance_spy(SidekiqUniqueJobs::Lock::WhileExecuting) }

      before do
        allow(middleware).to receive(:unique_enabled?).and_return(true)
        allow(middleware).to receive(:lock).and_return(lock)
      end

      it 'executes the lock' do
        expect(lock).to receive(:execute).with(instance_of(Proc)).and_yield
        subject
      end
    end

    describe '#unlock' do
      it 'does not unlock keys it does not own' do
        jid = UntilExecutedJob.perform_async
        item = Sidekiq::Queue.new(queue).find_job(jid).item

        locksmith = SidekiqUniqueJobs::Locksmith.new(item)

        Sidekiq.redis do |conn|
          expect(conn.get(locksmith.exists_key)).to eq(jid)
          conn.set(locksmith.exists_key, 'NOT_DELETED')
        end

        middleware.call(UntilExecutedJob.new, item, queue) do
          Sidekiq.redis do |conn|
            expect(conn.get(locksmith.exists_key)).to eq('NOT_DELETED')
          end
        end
      end
    end

    describe ':before_yield' do
      it 'removes the lock before yielding to the worker' do
        jid = UntilExecutingJob.perform_async
        item = Sidekiq::Queue.new(queue).find_job(jid).item
        worker = UntilExecutingJob.new

        middleware.call(worker, item, queue) do
          Sidekiq.redis do |conn|
            conn.keys('unique:*').each do |key|
              expect(conn.ttl(key)).to eq(-2) # key does not exist
            end
          end
        end
      end
    end

    describe ':after_yield' do
      it 'removes the lock after yielding to the worker' do
        jid = UntilExecutedJob.perform_async
        item = Sidekiq::Queue.new(queue).find_job(jid).item

        middleware.call('UntilExecutedJob', item, queue) do
          Sidekiq.redis do |conn|
            conn.keys('unique:*').each do |key|
              expect(conn.get(key)).to eq(-2) # key does not exist
            end
          end
        end
      end
    end
  end
end
