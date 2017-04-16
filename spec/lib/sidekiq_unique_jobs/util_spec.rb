require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Util do
  let(:job) do
    {
      'class' => 'MyUniqueJob',
      'args' => [[1, 2]],
      'at' => 1_492_341_850.358196,
      'retry' => true,
      'queue' => 'customqueue',
      'unique' => :until_executed,
      'unique_expiration' => 7200,
      'retry_count' => 10,
      'jid' => jid,
      'created_at' => 1_492_341_790.358217,
    }
  end
  let(:unique_args) { SidekiqUniqueJobs::UniqueArgs.new(job) }
  let(:unique_key) { unique_args.unique_digest }
  let(:jid) { 'e3049b05b0bd9c809182bbe0' }

  def acquire_lock
    SidekiqUniqueJobs::Scripts::AcquireLock.execute(nil, unique_key, jid, 1)
  end

  describe '.keys' do
  end

  describe '.del' do
    before do
      acquire_lock
    end

    it 'deletes the keys by pattern' do
      expect(described_class.del(described_class::SCAN_PATTERN, 100, false)).to eq(1)
    end

    it 'deletes the keys by distinct key' do
      expect(described_class.del(unique_key, 100, false)).to eq(1)
    end
  end

  describe '.expire' do
    before do
      acquire_lock
    end

    it 'does some shit' do
      sleep 1
      expected = { jid => unique_key }
      expect(described_class.unique_hash).to match(expected)
      removed_keys = described_class.expire
      expect(removed_keys).to match(expected)
      expect(described_class.unique_hash).not_to match(expected)
      expect(described_class.keys('*')).not_to include(unique_key)
    end
  end

  describe '.prefix' do
    before do
      allow(SidekiqUniqueJobs.config).to receive(:unique_prefix).and_return('test-uniqueness')
    end

    it 'returns a prefixed key' do
      expect(described_class.prefix('key')).to eq('test-uniqueness:key')
    end

    context 'when .unique_prefix is nil?' do
      it 'does not prefix with unique_prefix' do
        allow(SidekiqUniqueJobs.config).to receive(:unique_prefix).and_return(nil)
        expect(described_class.prefix('key')).to eq('key')
      end
    end

    context 'when key is already prefixed' do
      it 'does not add another prefix' do
        expect(described_class.prefix('test-uniqueness:key')).to eq('test-uniqueness:key')
      end
    end
  end
end
