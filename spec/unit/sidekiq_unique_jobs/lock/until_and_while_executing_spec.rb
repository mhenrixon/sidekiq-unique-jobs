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
    let(:server_lock) { instance_spy(SidekiqUniqueJobs::Lock::WhileExecuting) }

    before do
      allow(lock).to receive(:locked?).and_return(locked?)
      allow(lock).to receive(:delete!).and_return(true)
      allow(lock).to receive(:server_lock).and_return(server_lock)
      allow(server_lock).to receive(:execute).with(callback).and_yield
    end

    context 'when locked?' do
      let(:locked?) { true }

      it 'unlocks the unique key before yielding' do
        inside_block_value = false

        lock.execute(callback) { inside_block_value = true }
        expect(inside_block_value).to eq(true)

        expect(lock).to have_received(:locked?)
        expect(lock).to have_received(:delete!)
        expect(server_lock).to have_received(:execute).with(callback)
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
        expect(server_lock).not_to have_received(:execute).with(callback)
      end
    end
  end
end
