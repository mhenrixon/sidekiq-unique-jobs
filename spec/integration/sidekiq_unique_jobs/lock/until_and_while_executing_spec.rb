# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilAndWhileExecuting, redis: :redis, redis_db: 3 do
  let(:lock) { described_class.new(item) }
  let(:item) do
    {
      'jid' => 'maaaahjid',
      'queue' => 'dupsallowed',
      'class' => 'UntilAndWhileExecutingJob',
      'unique' => 'until_and_while_executing',
      'args' => [1],
    }
  end
  let(:callback) { -> {} }

  describe '#execute' do
    let(:runtime_lock) { SidekiqUniqueJobs::Lock::WhileExecuting.new(item_copy) }
    let(:item_copy) do
      lock.instance_variable_get(:@item).dup
    end

    before do
      allow(lock).to receive(:runtime_lock).and_return(runtime_lock)
      lock.lock
      expect(lock.locked?).to eq(true)
    end

    after { lock.delete }

    it 'unlocks the unique key before yielding' do
      allow(callback).to receive(:call)

      lock.execute(callback) do
        10.times { Sidekiq::Client.push(item) }

        expect(unique_keys.size).to eq(3)
      end

      expect(lock.locked?).to eq(false)
      expect(unique_keys.size).to eq(0)
      expect(runtime_lock.locked?).to eq(false)
      expect(callback).to have_received(:call)
    end
  end
end
