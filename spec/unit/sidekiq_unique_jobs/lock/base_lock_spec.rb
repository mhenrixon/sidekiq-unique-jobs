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
    it do
      expect(locksmith).to receive(:lock).with(kind_of(Integer)).and_return('token')
      expect(lock.lock).to eq('token')
    end
  end

  describe '#execute' do
    it do
      expect { lock.execute(nil) }
        .to raise_error(NotImplementedError, "#execute needs to be implemented in #{described_class}")
    end
  end

  describe '#unlock' do
    let(:token) { 'another-token' }

    before do
      allow(locksmith).to receive(:lock).with(kind_of(Integer)).and_return(token)
      lock.lock
    end

    it do
      allow(locksmith).to receive(:signal).with(token).and_return('unlocked')

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
