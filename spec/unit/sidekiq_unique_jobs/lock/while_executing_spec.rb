# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecuting do
  include_context 'with a stubbed locksmith'

  let(:item) do
    { 'jid' => 'maaaahjid',
      'class' => 'WhileExecutingJob',
      'unique' => 'while_executing',
      'args' => [%w[array of arguments]] }
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

  describe '#execute' do
    subject(:execute) { lock.execute(empty_callback) }

    let(:token) { nil }

    before do
      allow(locksmith).to receive(:lock).with(0).and_return(token)
      allow(lock).to receive(:using_protection).with(empty_callback).and_yield

      execute
    end

    context 'when lock succeeds' do
      let(:token) { 'a token' }

      it { expect(lock).to have_received(:using_protection) }
    end

    context 'when lock fails' do
      let(:token) { nil }

      it { expect(lock).not_to have_received(:using_protection) }
    end
  end
end
