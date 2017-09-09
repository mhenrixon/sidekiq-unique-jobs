# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Util, redis: :redis do
  let(:item_hash) do
    {
      'class'       => 'MyUniqueJob',
      'args'        => [[1, 2]],
      'at'          => 1_492_341_850.358196,
      'retry'       => true,
      'queue'       => 'customqueue',
      'unique'      => :until_executed,
      'expiration'  => 7200,
      'retry_count' => 10,
      'jid'         => jid,
      'created_at'  => 1_492_341_790.358217,
    }
  end
  let!(:item) do
    my_item = item_hash.dup
    SidekiqUniqueJobs::UniqueArgs.new(my_item).unique_digest
    my_item
  end

  let(:unique_key) { item['unique_digest'] }
  let(:jid)        { 'e3049b05b0bd9c809182bbe0' }
  let(:lock)       { SidekiqUniqueJobs::Lock.new(item) }
  let(:expected_keys) do
    %W[
      #{unique_key}:EXISTS
      #{unique_key}:GRABBED
    ]
  end

  describe '.keys' do
    subject { described_class.keys }
    before do
      expect(described_class.keys).to match_array([])
      lock.lock(0)
    end

    it { is_expected.to match_array(expected_keys) }
  end

  describe '.del' do
    subject { described_class.del(pattern, 100, false) }

    before do
      lock.lock(0)
      expect(described_class.keys).to match_array(expected_keys)
    end

    context 'when pattern is a wildcard' do
      let(:pattern) { described_class::SCAN_PATTERN }

      it { is_expected.to eq(2) }
    end

    context 'when pattern is a specific key' do
      let(:pattern) { unique_key }

      it { is_expected.to eq(2) }
    end

    after do
      expect(described_class.keys).to match_array([])
      lock.unlock
      lock.delete!
    end
  end

  describe '.prefix' do
    subject { described_class.send(:prefix, key) }

    let(:key) { 'key' }

    context 'when prefix is configured' do
      before { allow(SidekiqUniqueJobs.config).to receive(:unique_prefix).and_return('test-uniqueness') }

      it { is_expected.to eq('test-uniqueness:key') }

      context 'when key is already prefixed' do
        let(:key) { 'test-uniqueness:key' }

        it { is_expected.to eq('test-uniqueness:key') }
      end
    end

    context 'when .unique_prefix is nil?' do
      before { allow(SidekiqUniqueJobs.config).to receive(:unique_prefix).and_return(nil) }

      it { is_expected.to eq('key') }
    end
  end
end
