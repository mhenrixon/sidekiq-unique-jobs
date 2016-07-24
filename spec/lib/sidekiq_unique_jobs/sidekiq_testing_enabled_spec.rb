require 'spec_helper'
require 'sidekiq/worker'
require 'sidekiq-unique-jobs'
require 'sidekiq/scheduled'

RSpec.describe 'When Sidekiq::Testing is enabled' do
  describe 'when set to :fake!', sidekiq: :fake do
    before do
      SidekiqUniqueJobs.configure do |config|
        config.redis_test_mode = :redis
      end
      Sidekiq.redis = REDIS
      Sidekiq.redis(&:flushdb)
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.server_middleware do |chain|
        chain.add SidekiqUniqueJobs::Server::Middleware
      end if Sidekiq::Testing.respond_to?(:server_middleware)
    end

    after do
      Sidekiq.redis(&:flushdb)
      Sidekiq::Testing.server_middleware(&:clear) if Sidekiq::Testing.respond_to?(:server_middleware)
    end

    context 'with unique worker' do
      it 'does not push duplicate messages' do
        param = 'work'
        expect(UntilExecutedJob.jobs.size).to eq(0)
        expect(UntilExecutedJob.perform_async(param)).to_not be_nil
        expect(UntilExecutedJob.jobs.size).to eq(1)
        expect(UntilExecutedJob.perform_async(param)).to be_nil
        expect(UntilExecutedJob.jobs.size).to eq(1)
      end

      it 'unlocks jobs after draining a worker' do
        param = 'work'
        param2 = 'more work'

        expect(UntilExecutedJob.jobs.size).to eq(0)
        UntilExecutedJob.perform_async(param)
        UntilExecutedJob.perform_async(param2)
        expect(UntilExecutedJob.jobs.size).to eq(2)
        UntilExecutedJob.drain
        expect(UntilExecutedJob.jobs.size).to eq(0)
        UntilExecutedJob.perform_async(param)
        UntilExecutedJob.perform_async(param2)
        expect(UntilExecutedJob.jobs.size).to eq(2)
      end

      it 'unlocks a single job when calling perform_one' do
        param = 'work'
        param2 = 'more work'
        expect(UntilExecutedJob.jobs.size).to eq(0)
        UntilExecutedJob.perform_async(param)
        UntilExecutedJob.perform_async(param2)
        expect(UntilExecutedJob.jobs.size).to eq(2)
        UntilExecutedJob.perform_one
        expect(UntilExecutedJob.jobs.size).to eq(1)
        UntilExecutedJob.perform_async(param2)
        expect(UntilExecutedJob.jobs.size).to eq(1)
        UntilExecutedJob.perform_async(param)
        expect(UntilExecutedJob.jobs.size).to eq(2)
      end

      it 'unlocks jobs cleared from a single worker' do
        param = 'work'
        param2 = 'more work'
        expect(UntilExecutedJob.jobs.size).to eq(0)
        expect(AnotherUniqueJob.jobs.size).to eq(0)
        UntilExecutedJob.perform_async(param)
        UntilExecutedJob.perform_async(param2)
        AnotherUniqueJob.perform_async(param)
        expect(UntilExecutedJob.jobs.size).to eq(2)
        expect(AnotherUniqueJob.jobs.size).to eq(1)
        UntilExecutedJob.clear
        expect(UntilExecutedJob.jobs.size).to eq(0)
        expect(AnotherUniqueJob.jobs.size).to eq(1)
        UntilExecutedJob.perform_async(param)
        UntilExecutedJob.perform_async(param2)
        AnotherUniqueJob.perform_async(param)
        expect(UntilExecutedJob.jobs.size).to eq(2)
        expect(AnotherUniqueJob.jobs.size).to eq(1)
      end

      it 'handles clearing an empty worker queue' do
        param = 'work'
        UntilExecutedJob.perform_async(param)
        UntilExecutedJob.drain
        expect(UntilExecutedJob.jobs.size).to eq(0)
        expect { UntilExecutedJob.clear }.not_to raise_error
      end

      it 'unlocks jobs when all workers are cleared' do
        param = 'work'
        expect(UntilExecutedJob.jobs.size).to eq(0)
        expect(AnotherUniqueJob.jobs.size).to eq(0)
        UntilExecutedJob.perform_async(param)
        AnotherUniqueJob.perform_async(param)
        expect(UntilExecutedJob.jobs.size).to eq(1)
        expect(AnotherUniqueJob.jobs.size).to eq(1)
        Sidekiq::Worker.clear_all
        expect(UntilExecutedJob.jobs.size).to eq(0)
        expect(AnotherUniqueJob.jobs.size).to eq(0)
        UntilExecutedJob.perform_async(param)
        expect(UntilExecutedJob.jobs.size).to eq(1)
        AnotherUniqueJob.perform_async(param)
        expect(AnotherUniqueJob.jobs.size).to eq(1)
      end

      it 'handles clearing all workers when there are no jobs' do
        param = 'work'
        UntilExecutedJob.perform_async(param)
        AnotherUniqueJob.perform_async(param)
        Sidekiq::Worker.clear_all
        expect(UntilExecutedJob.jobs.size).to eq(0)
        expect(AnotherUniqueJob.jobs.size).to eq(0)
        expect { Sidekiq::Worker.jobs.size }.not_to raise_error
      end

      it 'adds the unique_digest to the message' do
        param = 'hash'
        item = { 'class' => 'UntilExecutedJob', 'queue' => 'working', 'args' => [param] }
        hash = SidekiqUniqueJobs::UniqueArgs.digest(item)
        expect(UntilExecutedJob.perform_async(param)).to_not be_nil
        expect(UntilExecutedJob.jobs.size).to eq(1)
        expect(UntilExecutedJob.jobs.last['unique_digest']).to eq(hash)
      end
    end

    context 'with non-unique worker' do
      it 'pushes duplicates messages' do
        param = 'work'
        expect(MyJob.jobs.size).to eq(0)
        MyJob.perform_async(param)
        expect(MyJob.jobs.size).to eq(1)
        MyJob.perform_async(param)
        expect(MyJob.jobs.size).to eq(2)
      end
    end
  end

  describe 'when set to :inline!', sidekiq: :inline do
    it 'once the job is completed allows to run another one' do
      expect(TestClass).to receive(:run).with('test').twice
      InlineWorker.perform_async('test')
      InlineWorker.perform_async('test')
    end

    it 'if the unique is kept forever it does not allows to run the job again' do
      expect(TestClass).to receive(:run).with('args').once

      UntilGlobalTimeoutJob.perform_async('args')
      UntilGlobalTimeoutJob.perform_async('args')
    end

    describe 'when a job is set to run once in 10 minutes' do
      context 'when spammed' do
        it 'only allows 1 call per 10 minutes' do
          expect(TestClass).to receive(:run).with(1).once
          100.times do
            UntilTimeoutJob.perform_async(1)
          end
        end
      end

      context 'with different arguments' do
        it 'only allows 1 call per 10 minutes' do
          expect(TestClass).to receive(:run).with(9).once
          2.times do
            UntilTimeoutJob.perform_async(9)
          end

          expect(TestClass).to receive(:run).with(2).once
          2.times do
            UntilTimeoutJob.perform_async(2)
          end
        end
      end
    end
  end
end
