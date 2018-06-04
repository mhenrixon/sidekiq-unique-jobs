# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/worker'
require 'sidekiq-unique-jobs'
require 'sidekiq/scheduled'

RSpec.shared_examples 'Sidekiq::Testing.fake!' do
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
      param = 'work 2'
      param2 = 'more work 2'
      expect(UntilExecutedJob.jobs.size).to eq(0)
      expect(UntilExecutedJob.perform_async(param)).not_to be_nil
      expect(UntilExecutedJob.perform_async(param2)).not_to be_nil
      expect(UntilExecutedJob.jobs.size).to eq(2)
      UntilExecutedJob.drain
      expect(UntilExecutedJob.jobs.size).to eq(0)
      expect(UntilExecutedJob.perform_async(param)).not_to be_nil
      expect(UntilExecutedJob.perform_async(param2)).not_to be_nil
      expect(UntilExecutedJob.jobs.size).to eq(2)
    end

    it 'unlocks a single job when calling perform_one' do
      param = 'work 3'
      param2 = 'more work 3'
      expect(UntilExecutedJob.jobs.size).to eq(0)
      expect(UntilExecutedJob.perform_async(param)).not_to be_nil
      expect(UntilExecutedJob.perform_async(param2)).not_to be_nil
      expect(UntilExecutedJob.jobs.size).to eq(2)
      UntilExecutedJob.perform_one
      expect(UntilExecutedJob.jobs.size).to eq(1)
      expect(UntilExecutedJob.perform_async(param2)).to be_nil
      expect(UntilExecutedJob.jobs.size).to eq(1)
      expect(UntilExecutedJob.perform_async(param)).not_to be_nil
      expect(UntilExecutedJob.jobs.size).to eq(2)
    end

    it 'unlocks jobs cleared from a single worker' do
      param = 'work 4'
      param2 = 'more work 4'
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
      param = 'work 5'
      UntilExecutedJob.perform_async(param)
      UntilExecutedJob.drain
      expect(UntilExecutedJob.jobs.size).to eq(0)
      expect { UntilExecutedJob.clear }.not_to raise_error
    end

    it 'unlocks jobs when all workers are cleared' do
      param = 'work 6'
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
      param = 'work 7'
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
      digest = SidekiqUniqueJobs::UniqueArgs.digest(item)
      expect(UntilExecutedJob.perform_async(param)).to_not be_nil
      expect(UntilExecutedJob.jobs.size).to eq(1)
      expect(UntilExecutedJob.jobs.last['unique_digest']).to eq(digest)
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

RSpec.describe Sidekiq::Testing, 'with Redis', redis: :redis, redis_db: 12, sidekiq: :fake do
  it_behaves_like 'Sidekiq::Testing.fake!'
end

RSpec.describe Sidekiq::Testing, 'with MockRedis', redis: :mock_redis, sidekiq: :fake do
  it_behaves_like 'Sidekiq::Testing.fake!'
end
