require 'spec_helper'
require 'sidekiq/worker'
require 'sidekiq-unique-jobs'
require 'sidekiq/scheduled'
require 'sidekiq_unique_jobs/middleware/server/unique_jobs'
require 'rspec-sidekiq'

describe 'When Sidekiq::Testing is enabled' do
  describe 'when set to :fake!', sidekiq: :fake do
    context 'with unique worker' do
      it 'does not push duplicate messages' do
        param = 'work'
        expect(UniqueWorker.jobs.size).to eq(0)
        UniqueWorker.perform_async(param)
        expect(UniqueWorker.jobs.size).to eq(1)
        expect(UniqueWorker).to have_enqueued_job(param)
        UniqueWorker.perform_async(param)
        expect(UniqueWorker.jobs.size).to eq(1)
      end

      it 'adds the unique_hash to the message' do
        param = 'hash'
        hash = SidekiqUniqueJobs::PayloadHelper.get_payload(UniqueWorker, :working, [param])
        UniqueWorker.perform_async(param)
        expect(UniqueWorker.jobs.size).to eq(1)
        expect(UniqueWorker.jobs.first['unique_hash']).to eq(hash)
      end
    end

    context 'with non-unique worker' do

      it 'pushes duplicates messages' do
        param = 'work'
        expect(MyWorker.jobs.size).to eq(0)
        MyWorker.perform_async(param)
        expect(MyWorker.jobs.size).to eq(1)
        expect(MyWorker).to have_enqueued_job(param)
        MyWorker.perform_async(param)
        expect(MyWorker.jobs.size).to eq(2)
      end
    end
  end

  describe 'when set to :inline!', sidekiq: :inline do
    class InlineWorker
      include Sidekiq::Worker
      sidekiq_options unique: true

      def perform(x)
        TestClass.run(x)
      end
    end

    class InlineUnlockOrderWorker
      include Sidekiq::Worker
      sidekiq_options unique: true, unique_unlock_order: :never

      def perform(x)
        TestClass.run(x)
      end
    end

    class TestClass
      def self.run(_x)
      end
    end

    it 'once the job is completed allows to run another one' do
      expect(TestClass).to receive(:run).exactly(2).times

      InlineWorker.perform_async('test')
      InlineWorker.perform_async('test')
    end

    it 'if the unique is kept forever it does not allows to run the job again' do
      expect(TestClass).to receive(:run).once

      InlineUnlockOrderWorker.perform_async('test')
      InlineUnlockOrderWorker.perform_async('test')
    end
  end
end
