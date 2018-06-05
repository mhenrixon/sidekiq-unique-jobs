# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecuting, redis: :mock_redis do
  let(:lock) { described_class.new(item) }

  let(:item) do
    {
      'jid' => 'job-id',
      'class' => 'WhileExecutingJob',
      'unique' => 'while_executing'
    }
  end

  describe '#lock' do
    it { expect(lock.lock(:client)).to eq(true) }
  end

  describe '#execute' do
    it 'locks' do
      expect(@redis.keys.length).to eq(0)

      callback = spy
      lock.execute(callback) do
        expect(@redis.keys.length).to eq(2)
        expect(callback).not_to have_received(:call)
      end

      expect(@redis.keys.length).to eq(0)
      expect(callback).to have_received(:call)
    end

    it 'releases the lock even if the block raises' do
      expect do
        lock.execute(-> {}) do
          raise StandardError, 'fake error'
        end
      end.to raise_error(StandardError)

      expect(@redis.keys.length).to eq(0)
    end

    it 'does not raise an with a zero timeout if it cannot acquire' do
      duplicate_lock = described_class.new(item.merge(SidekiqUniqueJobs::LOCK_TIMEOUT_KEY => 0))
      block = -> {}

      lock.execute(-> {}) do
        expect(block).not_to receive(:call)
        expect { duplicate_lock.execute(-> {}, &block) }.not_to raise_error
      end
    end

    it 'raises with a non-zero timeout if it cannot acquire' do
      duplicate_lock = described_class.new(item.merge(SidekiqUniqueJobs::LOCK_TIMEOUT_KEY => 5))
      block = -> {}

      lock.execute(-> {}) do
        expect(block).not_to receive(:call)
        expect { duplicate_lock.execute(-> {}, &block) }.to raise_error(SidekiqUniqueJobs::LockTimeout)
      end
    end
  end
end
