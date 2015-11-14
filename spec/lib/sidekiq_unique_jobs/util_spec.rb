require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Util do
  let(:keys) { %w(uniquejobs:keyz) }

  def set(key, value)
    described_class.connection do |c|
      c.set(key, value)
      expect(c.keys('*')).to match_array([key])
    end
  end

  before(:each) do
    Sidekiq.redis = REDIS
    Sidekiq.redis(&:flushdb)
  end

  describe '.keys' do
  end

  describe '.del_by' do
    context 'given a key named "keyz" with value "valz"' do
      before do
        set('uniquejobs:keyz', 'valz')
      end

      it 'deletes the keys by pattern' do
        expect(described_class.del_by('*', count: 100, dry_run: false)).to eq(1)
      end

      it 'deletes the keys by pattern' do
        expect(described_class.del_by('keyz', count: 100, dry_run: false)).to eq(1)
      end
    end
  end

  describe '.prefix' do
    context 'when .unique_prefix is nil?' do
      it 'does not prefix with unique_prefix' do
        allow(SidekiqUniqueJobs.config).to receive(:unique_prefix).and_return(nil)
        expect(described_class.prefix('key')).to eq('key')
      end
    end

    before do
      allow(SidekiqUniqueJobs.config).to receive(:unique_prefix).and_return('test-uniqueness')
    end

    it 'returns a prefixed key' do
      expect(described_class.prefix('key')).to eq('test-uniqueness:key')
    end
  end
end
