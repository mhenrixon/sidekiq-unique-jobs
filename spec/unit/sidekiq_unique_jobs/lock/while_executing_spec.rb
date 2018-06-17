# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecuting do
  include_context 'with a stubbed locksmith'

  let(:item) do
    { 'jid' => 'maaaahjid',
      'class' => 'WhileExecutingJob',
      'unique' => 'while_executing',
      'args' => [['array', 'of', 'arguments']] }
  end
  let(:empty_callback) { -> {} }

  describe '.new' do
    specify do
      expect { described_class.new(item) }
        .to change { item['unique_digest'] }
        .to a_string_ending_with(':RUN')
    end
  end

  describe '#lock' do
    subject { lock.lock }

    it { is_expected.to eq(true) }
  end

  describe '#unlock' do
    subject { lock.unlock }

    it { is_expected.to eq(true) }
  end

  describe '#execute' do
    subject(:execute) { lock.execute(empty_callback) }

    it 'calls the callback' do
      expect(empty_callback).to receive(:call)
      expect(locksmith).to receive(:lock).with(0).and_yield

      execute
    end
  end
end
