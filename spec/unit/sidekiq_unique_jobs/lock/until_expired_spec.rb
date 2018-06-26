# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilExpired do
  include_context 'with a stubbed locksmith'

  let(:item) do
    { 'jid' => 'maaaahjid',
      'class' => 'UntilExpiredJob',
      'unique' => 'until_timeout' }
  end
  let(:empty_callback) { -> {} }

  describe '#unlock' do
    subject(:unlock) { lock.unlock }

    it { is_expected.to eq(true) }
  end

  before do
    allow(empty_callback).to receive(:call)
  end

  describe '#execute' do
    subject(:execute) { lock.execute(empty_callback) }

    let(:locked?) { false }

    before do
      allow(lock).to receive(:locked?).and_return(locked?)
    end

    context 'when locked?' do
      let(:locked?) { true }

      it 'calls back' do
        execute

        expect(empty_callback).to have_received(:call)
      end
    end

    context 'when not locked?' do
      it 'does not call back' do
        execute

        expect(empty_callback).not_to have_received(:call)
      end
    end
  end
end
