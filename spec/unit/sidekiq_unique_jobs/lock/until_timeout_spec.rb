# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilTimeout do
  include_context 'with a stubbed locksmith'

  let(:item) do
    { 'jid' => 'maaaahjid',
      'class' => 'UntilTimeoutJob',
      'unique' => 'until_timeout' }
  end
  let(:empty_callback) { -> {} }

  describe '#unlock' do
    subject(:unlock) { lock.unlock }

    it { is_expected.to eq(true) }
  end

  describe '#execute' do
    subject(:execute) { lock.execute(empty_callback) }

    it 'calls the callback' do
      expect(empty_callback).to receive(:call)
      execute
    end
  end
end
