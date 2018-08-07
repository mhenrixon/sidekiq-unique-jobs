# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FilePath
RSpec.describe SidekiqUniqueJobs::Locksmith, redis: :redis do
  let(:locksmith_one) { described_class.new(lock_item) }
  let(:lock_expiration) { nil }
  let(:redis_pool)      { nil }
  let(:jid_one)         { 'maaaahjid' }
  let(:jid_two)         { 'anotherjid' }
  let(:unique_digest)   { 'uniquejobs:test_mutex_key' }
  let(:queue)           { 'dupsallowed' }
  let(:unique)          { :until_executed }
  let(:worker_class)    { UntilExecutedJob }
  let(:lock_item) do
    {
      'args' => [1],
      'class' => UntilExecutedJob,
      'jid' => jid_one,
      'lock_expiration' => lock_expiration,
      'queue' => queue,
      'lock' => unique,
      'unique_digest' => unique_digest,
    }
  end

  let(:locksmith_two) { described_class.new(lock_item_two) }
  let(:lock_item_two) { lock_item.merge('jid' => jid_two) }

  context 'with a legacy uniquejobs hash' do
    before do
      SidekiqUniqueJobs.redis do |conn|
        conn.multi do
          conn.hset('uniquejobs', 'bogus', 'value')
          conn.hset('uniquejobs', 'bogus', 'value 2')
        end
      end
    end

    it 'deletes the uniquejobs hash' do
      expect(keys).to include('uniquejobs')
      expect(hexists('uniquejobs', 'bogus')).to eq(true)
      locksmith_one.delete
      expect(keys).not_to include('uniquejobs')
      expect(hexists('uniquejobs', 'bogus')).to eq(false)
    end
  end

  context 'with a legacy lock' do
    before do
      result = SidekiqUniqueJobs::Scripts.call(
        :acquire_lock,
        redis_pool,
        keys: [unique_digest],
        argv: [lock_value, lock_expiration],
      )

      expect(result).to eq(1)
      expect(unique_keys).to include(unique_digest)
    end

    context 'when lock_expiration is unset' do
      let(:lock_value) { jid_one }

      it 'unlocks immediately' do
        locksmith_one.unlock!(jid_one)

        expect(ttl(unique_digest)).to eq(-2) # key does not exist anymore
      end

      it 'can soft deletes the lock' do
        expect(locksmith_one.delete).to eq(nil)
        expect(unique_keys).not_to include(unique_digest)
      end

      it 'can force delete the lock' do
        expect(locksmith_one.delete!).to eq(nil)
        expect(unique_keys).not_to include(unique_digest)
      end
    end

    context 'when lock_expiration is set' do
      let(:lock_value)      { jid_one }
      let(:lock_expiration) { 10 }

      it 'can signal to expire the lock after 10' do
        locksmith_one.unlock(jid_one)

        expect(ttl(unique_digest)).to be_within(1).of(10)
      end

      it 'cannot soft delete the lock' do
        expect(locksmith_one.delete).to eq(nil)
        expect(unique_keys).to include(unique_digest)
      end

      it 'can force delete the lock' do
        expect(locksmith_one.delete!).to eq(nil)
        expect(unique_keys).not_to include(unique_digest)
      end
    end

    context 'when the value of unique_digest is 2' do
      let(:lock_value) { '2' }

      it 'returns the stored jid' do
        expect(locksmith_one.lock(0)).to eq(jid_one)
      end
    end

    context 'when the value of unique_digest is jid' do
      let(:lock_value) { jid_one }

      it 'returns the stored jid' do
        expect(locksmith_one.lock(0)).to eq(jid_one)
      end

      it 'can not be locked by another jid' do
        expect(locksmith_two.lock(0)).to eq(nil)
      end
    end
  end
end
# rubocop:enable RSpec/FilePath
