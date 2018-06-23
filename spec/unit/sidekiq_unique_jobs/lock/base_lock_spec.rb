# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::BaseLock do
  include_context 'with a stubbed locksmith'

  let(:item) do
    {
      'jid' => 'maaaahjid',
      'queue' => 'default',
      'class' => 'UntilExecutedJob',
      'unique' => :until_executed,
      'args' => [1],
    }
  end

  describe '#lock' do
    subject(:lock_lock) { lock.lock }

    before do
      allow(locksmith).to receive(:lock).with(kind_of(Integer)).and_return(token)
    end

    context 'when a token is retrieved' do
      let(:token) { 'another jid' }

      it { is_expected.to eq('another jid') }
    end

    context 'when token is not retrieved' do
      let(:token) { nil }

      it { is_expected.to eq(nil) }
    end
  end

  describe '#execute' do
    it do
      expect { lock.execute(nil) }
        .to raise_error(NotImplementedError, "#execute needs to be implemented in #{described_class}")
    end
  end

  describe '#unlock' do
    it do
      allow(locksmith).to receive(:signal).with(item['jid']).and_return('unlocked')

      expect(lock.unlock).to eq('unlocked')
    end
  end

  describe '#delete' do
    it do
      allow(locksmith).to receive(:unlock)
      allow(locksmith).to receive(:delete).and_return('deleted')

      expect(lock.delete).to eq('deleted')
    end
  end

  describe '#locked?' do
    it do
      allow(locksmith).to receive(:locked?).and_return(true)

      expect(lock.locked?).to eq(true)
    end
  end
end
