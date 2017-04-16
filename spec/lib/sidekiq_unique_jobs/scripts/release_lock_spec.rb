require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Scripts::ReleaseLock do
  let(:redis_pool) { nil }
  let(:jid) { 'abcdefab' }
  let(:unique_key) { 'uniquejobs:123asdasd2134' }
  let(:max_lock_time) { 1 }

  describe '.execute' do
    subject { instance_double(described_class) }

    it 'delegates to instance' do
      expect(described_class).to receive(:new)
        .with(redis_pool, unique_key, jid)
        .and_return(subject)
      expect(subject).to receive(:execute).and_return(true)

      described_class.execute(redis_pool, unique_key, jid)
    end
  end

  describe '#execute' do
    context 'when exists' do
      subject { described_class.execute(redis_pool, unique_key, jid) }

      before do
        SidekiqUniqueJobs::Scripts::AcquireLock.execute(redis_pool, unique_key, jid, max_lock_time)
      end

      specify do
        expect(SidekiqUniqueJobs)
          .to have_key(unique_key)
          .for_seconds(max_lock_time)
          .with_value(jid)

        expect(subject).to eq(true)
        expect(SidekiqUniqueJobs).not_to have_key(unique_key)
      end
    end
  end
end
