# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilAndWhileExecuting do
  include_context 'lock with a stubbed locksmith'
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
      allow(lock).to receive(:runtime_lock).and_return(runtime_lock)
    end

    it 'unlocks the unique key before yielding' do
      allow(lock).to receive(:unlock).and_return(true)

      inside_block_value = false
      expect(runtime_lock).to receive(:execute).with(callback).and_yield

      lock.execute(callback) { inside_block_value = true }
      expect(inside_block_value).to eq(true)
    end
  end
end
