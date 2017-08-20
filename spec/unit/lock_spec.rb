# frozen_string_literal: true

require 'spec_helper'
require 'rspec/wait'

RSpec.shared_context 'a lock setup' do
  let(:lock)                      { described_class.new(lock_item) }
  let(:lock_expiration)           { nil }
  let(:lock_use_local_time)       { false }
  let(:lock_stale_client_timeout) { nil }
  let(:jid)                       { 'maaaahjid' }
  let(:lock_item) do
    {
      'jid' => jid,
      'queue' => 'dupsallowed',
      'class' => 'UntilAndWhileExecuting',
      'unique' => 'until_executed',
      'unique_digest' => 'test_mutex_key',
      'args' => [1],
      'lock_expiration' => lock_expiration,
      'use_local_time' => lock_use_local_time,
      'stale_client_timeout' => lock_stale_client_timeout,
    }
  end
  let(:lock_with_different_jid) { described_class.new(lock_item_with_different_jid) }
  let(:jid_2)                   { 'jidmayhem' }
  let(:lock_item_with_different_jid) do
    lock_item.merge('jid' => jid_2)
  end
end

RSpec.shared_examples_for 'a lock' do
  it 'should not exist from the start' do
    expect(lock.exists?).to eq(false)
    lock.lock
    expect(lock.exists?).to eq(true)
  end

  it 'should be unlocked from the start' do
    expect(lock.locked?).to eq(false)
  end

  it 'should lock and unlock' do
    lock.lock(1)
    expect(lock.locked?).to eq(true)
    lock.unlock
    expect(lock.locked?).to eq(false)
  end

  it 'should not lock twice as a mutex' do
    expect(lock.lock(1)).not_to eq(false)
    expect(lock.lock(1)).to eq(false)
  end

  it 'should execute the given code block' do
    code_executed = false
    lock.lock(1) do
      code_executed = true
    end
    expect(code_executed).to eq(true)
  end

  it 'should pass an exception right through' do
    expect do
      lock.lock(1) do
        raise Exception, 'redis lock exception'
      end
    end.to raise_error(Exception, 'redis lock exception')
  end

  it 'should not leave the lock locked after raising an exception' do
    expect do
      lock.lock(1) do
        raise Exception, 'redis lock exception'
      end
    end.to raise_error(Exception, 'redis lock exception')

    expect(lock.locked?).to eq(false)
  end

  it 'should return the value of the block if block-style locking is used' do
    block_value = lock.lock(1) do
      42
    end
    expect(block_value).to eq(42)
  end

  it 'should disappear without a trace when calling `delete!`' do
    original_key_size = SidekiqUniqueJobs.connection { |conn| conn.keys.count }

    lock.exists_or_create!
    lock.delete!

    expect(SidekiqUniqueJobs.connection { |conn| conn.keys.count }).to eq(original_key_size)
  end

  it 'should not block when the timeout is zero' do
    did_we_get_in = false

    lock.lock do
      lock.lock(0) do
        did_we_get_in = true
      end
    end

    expect(did_we_get_in).to be false
  end

  it 'should be locked when the timeout is zero' do
    lock.lock(0) do
      expect(lock.locked?).to be true
    end
  end
end

RSpec.shared_examples 'a real lock' do
  describe 'lock with expiration' do
    let(:lock_expiration) { 1 }

    it_behaves_like 'a lock'

    def current_keys
      SidekiqUniqueJobs.connection(&:keys)
    end

    it 'expires keys' do
      Sidekiq.redis(&:flushdb)
      lock.exists_or_create!
      keys = current_keys
      expect(current_keys).not_to include(keys)
    end

    it 'expires keys after unlocking' do
      Sidekiq.redis(&:flushdb)
      lock.lock do
        # noop
      end
      keys = current_keys
      sleep 3.0
      expect(current_keys).not_to include(keys)
    end
  end

  describe 'lock without staleness checking' do
    it_behaves_like 'a lock'

    xit 'can have stale locks released by a third process' do
      watchdog = described_class.new(lock_item.merge('stale_client_timeout' => 1))
      lock.lock

      sleep 0.3
      watchdog.release_stale_locks!
      expect(lock.locked?).to eq(true)

      sleep 0.6

      watchdog.release_stale_locks!
      expect(lock.locked?).to eq(false)
    end
  end

  describe 'lock with staleness checking' do
    let(:lock_stale_client_timeout) { 5 }

    context 'when redis_version is old' do
      before do
        allow(SidekiqUniqueJobs).to receive(:redis_version).and_return('3.0')
      end

      it_behaves_like 'a lock'

      it 'should restore resources of stale clients', redis: :redis do
        another_lock_item = lock_item.merge('jid' => 'abcdefab', 'stale_client_timeout' => 1)
        hyper_aggressive_lock = described_class.new(another_lock_item)

        expect(hyper_aggressive_lock.lock(1)).not_to eq(false)
        expect(hyper_aggressive_lock.lock(1)).to eq(false)
        expect(hyper_aggressive_lock.lock(1)).not_to eq(false)
      end
    end

    context 'when redis_version is new', redis: :redis do
      before do
        allow(SidekiqUniqueJobs).to receive(:redis_version).and_return('4.0')
      end

      it_behaves_like 'a lock'

      it 'should restore resources of stale clients' do
        another_lock_item = lock_item.merge('jid' => 'abcdefab', 'stale_client_timeout' => 1)
        hyper_aggressive_lock = described_class.new(another_lock_item)

        expect(hyper_aggressive_lock.lock(1)).not_to eq(false)
        expect(hyper_aggressive_lock.lock(1)).to eq(false)
        expect(hyper_aggressive_lock.lock(1)).not_to eq(false)
      end
    end
  end
end

RSpec.describe SidekiqUniqueJobs::Lock, 'with Redis', redis: :redis do
  include_context 'a lock setup'
  it_behaves_like 'a real lock'

  describe 'redis time' do
    let(:lock_stale_client_timeout) { 5 }

    before(:all) do
      Timecop.freeze(Time.local(1990))
    end

    it 'with time support should return a different time than frozen time' do
      expect(lock.send(:current_time)).not_to eq(Time.now)
    end

    context 'when use_local_time is true' do
      let(:lock_use_local_time) { true }

      it 'with use_local_time should return the same time as frozen time' do
        expect(lock.send(:current_time)).to eq(Time.now)
      end
    end
  end
end

RSpec.describe SidekiqUniqueJobs::Lock, 'with MockRedis', redis: :mock_redis do
  require 'mock_redis'
  include_context 'a lock setup'
  it_behaves_like 'a real lock'

  describe 'redis time' do
    subject { lock.send(:current_time) }

    let(:lock_stale_client_timeout) { 5 }

    before(:all) do
      Timecop.freeze(Time.local(1990))
    end

    # Since we are never hitting a redis server
    # MockRedis uses ruby time for this
    it { is_expected.to eq(Time.now) }

    context 'when use_local_time is true' do
      let(:lock_use_local_time) { true }

      it { is_expected.to eq(Time.now) }
    end
  end
end
