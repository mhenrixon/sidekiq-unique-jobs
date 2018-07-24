# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::BaseLock do
  include_context 'with a stubbed locksmith'
  let(:lock)     { described_class.new(item, callback) }
  let(:callback) { -> {} }
  let(:unique_digest) { 'woohoounique' }
  let(:item) do
    {
      'jid' => 'maaaahjid',
      'queue' => 'default',
      'class' => 'UntilExecutedJob',
      'lock' => :until_executed,
      'args' => [1],
    }
  end

  class FailedExecutingLock < SidekiqUniqueJobs::Lock::BaseLock
    def execute
      with_cleanup { yield }
    end
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
      expect { lock.execute }
        .to raise_error(NotImplementedError, "#execute needs to be implemented in #{described_class}")
    end

    context 'when an implementation raises Sidekiq::Shutdown while excuting' do
      let(:lock) { FailedExecutingLock.new(item, callback) }

      it do
        allow(lock).to receive(:unlock_with_callback)
        allow(lock).to receive(:log_fatal)
        expect { lock.execute { raise Sidekiq::Shutdown, 'boohoo' } }
          .to raise_error(Sidekiq::Shutdown, 'boohoo')

        expect(lock).not_to have_received(:unlock_with_callback)
        expect(lock).to have_received(:log_fatal)
          .with('the unique_key: uniquejobs:f5dc601c1dd12f78de3013c7a2a930c0 needs to be unlocked manually')
      end
    end
  end

  describe '#unlock' do
    subject(:unlock) { lock.unlock }

    before do
      allow(locksmith).to receive(:signal).with(item['jid']).and_return('unlocked')
    end

    it { is_expected.to eq('unlocked') }
  end

  describe '#delete' do
    subject { lock.delete }

    before { allow(locksmith).to receive(:delete).and_return('deleted') }

    it { is_expected.to eq('deleted') }
  end

  describe '#delete!' do
    subject { lock.delete! }

    before { allow(locksmith).to receive(:delete!).and_return('deleted') }

    it { is_expected.to eq('deleted') }
  end

  describe '#locked?' do
    it do
      allow(locksmith).to receive(:locked?).and_return(true)

      expect(lock.locked?).to eq(true)
    end
  end
end
