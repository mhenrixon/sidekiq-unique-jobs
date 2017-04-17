# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Scripts::AcquireLock do
  let(:redis_pool) { nil }
  let(:jid) { 'abcdefab' }
  let(:unique_key) { 'uniquejobs:123asdasd2134' }
  let(:max_lock_time) { 1 }

  describe '.execute' do
    subject { instance_double(described_class) }

    it 'delegates to instance' do
      expect(described_class).to receive(:new)
        .with(redis_pool, unique_key, jid, max_lock_time)
        .and_return(subject)
      expect(subject).to receive(:execute).and_return(true)

      described_class.execute(redis_pool, unique_key, jid, max_lock_time)
    end
  end

  describe '#execute' do
    context 'when job is unique' do
      def execute(myjid = jid, key = unique_key, max_lock = max_lock_time)
        described_class.execute(
          redis_pool,
          key,
          myjid,
          max_lock,
        )
      end

      specify { expect(execute(jid, unique_key, max_lock_time)).to eq(true) }
      specify do
        expect(execute(jid, unique_key, max_lock_time)).to eq(true)
        expect(SidekiqUniqueJobs)
          .to have_key(unique_key)
          .for_seconds(max_lock_time)
          .with_value('abcdefab')
        sleep 0.5
        expect(execute).to eq(true)
      end

      context 'when a unique_key exists for another jid' do
        before  { expect(execute(jid, unique_key, 10)).to eq(true) }
        specify { expect(execute('anotherjid', unique_key, 5)).to eq(false) }
      end
    end
  end
end
