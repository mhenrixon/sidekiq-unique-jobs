# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FilePath
RSpec.describe SidekiqUniqueJobs::Locksmith, redis: :redis do
  let(:locksmith)       { described_class.new(lock_item) }
  let(:lock_expiration) { nil }
  let(:redis_pool)      { nil }
  let(:jid)             { 'maaaahjid' }
  let(:unique_digest)   { 'uniquejobs:test_mutex_key' }
  let(:queue)           { 'dupsallowed' }
  let(:unique)          { :until_executed }
  let(:worker_class)    { UntilExecutedJob }
  let(:lock_item) do
    {
      'args' => [1],
      'class' => UntilExecutedJob,
      'jid' => jid,
      'lock_expiration' => lock_expiration,
      'queue' => queue,
      'unique' => unique,
      'unique_digest' => unique_digest,
    }
  end
  let(:lock_with_different_jid) { described_class.new(lock_item_with_different_jid) }
  let(:jid_2)                   { 'jidmayhem' }
  let(:lock_item_with_different_jid) do
    lock_item.merge('jid' => jid_2)
  end

  context 'with a legacy lock' do
    before do
      SidekiqUniqueJobs::Scripts.call(
        :acquire_lock,
        redis_pool,
        keys: [unique_digest],
        argv: [jid, lock_expiration],
      )
    end

    context 'when lock_expiration is unset' do
      it 'can signal to expire the lock after 10' do
        locksmith.signal(jid)

        expect(ttl(unique_digest)).to eq(-2) # key does not exist
      end

      it 'can soft delete the lock' do
        expect(locksmith.delete).to eq(nil)
        expect(unique_keys).not_to include(unique_digest)
      end

      it 'can force delete the lock' do
        expect(locksmith.delete!).to eq(nil)
        expect(unique_keys).not_to include(unique_digest)
      end
    end

    context 'when lock_expiration is set' do
      let(:lock_expiration) { 10 }

      it 'can signal to expire the lock after 10' do
        locksmith.signal(jid)

        expect(ttl(unique_digest)).to be_within(1).of(10)
      end

      it 'cannot soft delete the lock' do
        expect(locksmith.delete).to eq(nil)
        expect(unique_keys).to include(unique_digest)
      end

      it 'can force delete the lock' do
        expect(locksmith.delete!).to eq(nil)
        expect(unique_keys).not_to include(unique_digest)
      end
    end

    it 'returns the stored jid' do
      expect(locksmith.lock).to eq(jid)
    end
  end
end
# rubocop:enable RSpec/FilePath
