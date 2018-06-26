# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilAndWhileExecuting do
  include_context 'with a stubbed locksmith'
  let(:item) do
    {
      'jid' => 'maaaahjid',
      'class' => 'UntilAndWhileExecutingJob',
      'unique' => 'until_and_while_executing',
      'args' => ['one'],
    }
  end
  let(:callback) { -> {} }

  describe '#execute' do
    let(:runtime_lock) { instance_spy(SidekiqUniqueJobs::Lock::WhileExecuting) }

    before do
      allow(lock).to receive(:locked?).and_return(locked?)
      allow(lock).to receive(:delete!).and_return(true)
      allow(lock).to receive(:runtime_lock).and_return(runtime_lock)
      allow(runtime_lock).to receive(:execute).with(callback).and_yield
    end

    context 'when locked?' do
      let(:locked?) { true }

      it 'unlocks the unique key before yielding' do
        inside_block_value = false

        lock.execute(callback) { inside_block_value = true }
        expect(inside_block_value).to eq(true)

        expect(lock).to have_received(:locked?)
        expect(lock).to have_received(:delete!)
        expect(runtime_lock).to have_received(:execute).with(callback)
      end
    end

    context 'when not locked?' do
      let(:locked?) { false }

      it 'unlocks the unique key before yielding' do
        inside_block_value = false
        lock.execute(callback) { inside_block_value = true }
        expect(inside_block_value).to eq(false)

        expect(lock).to have_received(:locked?)
        expect(lock).not_to have_received(:delete!)
        expect(runtime_lock).not_to have_received(:execute).with(callback)
      end
    end
  end

  describe '#runtime_lock' do
    subject(:runtime_lock) { lock.runtime_lock }

    it { is_expected.to be_a(SidekiqUniqueJobs::Lock::WhileExecuting) }

    it 'initializes with the right arguments' do
      allow(SidekiqUniqueJobs::Lock::WhileExecuting).to receive(:new)
      runtime_lock

      expect(SidekiqUniqueJobs::Lock::WhileExecuting)
        .to have_received(:new)
        .with(item, redis_pool)
    end
  end
end
