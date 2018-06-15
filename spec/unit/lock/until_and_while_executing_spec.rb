# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilAndWhileExecuting, redis: :redis, redis_db: 3 do
  let(:lock) { described_class.new(item) }
  let(:item) do
    {
      'jid' => 'maaaahjid',
      'queue' => 'dupsallowed',
      'class' => 'UntilAndWhileExecutingJob',
      'unique' => 'until_executed',
      'args' => [1],
    }
  end
  let(:callback) { -> {} }

  describe '#execute' do
    let(:runtime_lock) { SidekiqUniqueJobs::Lock::WhileExecuting.new(item) }

    before do
      allow(lock).to receive(:runtime_lock).and_return(runtime_lock)
      lock.lock(:client)
    end

    it 'unlocks the unique key before yielding' do
      allow(callback).to receive(:call)

      lock.execute(callback) do
        Sidekiq.redis do |conn|
          expect(conn.keys('uniquejobs:*').size).to eq(3)
        end

        10.times { Sidekiq::Client.push(item) }

        Sidekiq.redis do |conn|
          expect(conn.keys('uniquejobs:*').size).to eq(3)
        end
      end

      expect(callback).to have_received(:call)
    end
  end
end
