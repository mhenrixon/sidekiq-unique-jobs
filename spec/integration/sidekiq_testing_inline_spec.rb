# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/worker'
require 'sidekiq-unique-jobs'
require 'sidekiq/scheduled'

RSpec.shared_examples 'Sidekiq::Testing.inline!' do
  it 'once the job is completed allows to run another one' do
    expect(TestClass).to receive(:run).with('plosibubb').twice
    InlineWorker.perform_async('plosibubb')
    InlineWorker.perform_async('plosibubb')
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

RSpec.describe Sidekiq::Testing, 'with Redis', redis: :redis, redis_db: 13, sidekiq: :inline do
  it_behaves_like 'Sidekiq::Testing.inline!'
end

RSpec.describe Sidekiq::Testing, 'with MockRedis', redis: :mock_redis, sidekiq: :inline do
  it_behaves_like 'Sidekiq::Testing.inline!'
end
