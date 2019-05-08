# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Locksmith, redis: :redis, profile: true do
  let(:locksmith_one)   { described_class.new(item_one) }
  let(:locksmith_two)   { described_class.new(item_two) }

  let(:jid_one)         { "maaaahjid" }
  let(:jid_two)         { "jidmayhem" }
  let(:lock_expiration) { nil }
  let(:lock_type)       { "until_executed" }
  let(:unique_digest)   { "uniquejobs:randomvalue" }
  let(:key)             { SidekiqUniqueJobs::Key.new(unique_digest) }
  let(:lock_timeout)    { 0 }
  let(:lock_limit)      { 1 }
  let(:item_one) do
    {
      "jid" => jid_one,
      "unique_digest" => unique_digest,
      "lock_expiration" => lock_expiration,
      "lock" => lock_type,
      "lock_timeout" => lock_timeout,
      "lock_limit" => lock_limit,
    }
  end
  let(:item_two) { item_one.merge("jid" => jid_two) }

  shared_examples_for "a lock" do
    it "is unlocked from the start" do
      expect(locksmith_one).not_to be_locked
    end

    it "locks and unlocks" do
      locksmith_one.lock
      expect(locksmith_one).to be_locked
      locksmith_one.unlock
      expect(locksmith_one).not_to be_locked if lock_expiration.nil?
    end

    it "does not lock twice as a mutex" do
      expect(locksmith_one.lock).to be_truthy
      expect(locksmith_two.lock).to be_falsey
    end

    it "executes the given code block" do
      code_executed = false
      locksmith_one.lock do
        code_executed = true
      end
      expect(code_executed).to eq(true)
    end

    it "passes an exception right through" do
      expect do
        locksmith_one.lock do
          raise Exception, "redis lock exception"
        end
      end.to raise_error(Exception, "redis lock exception")
    end

    it "does not leave the lock locked after raising an exception" do
      expect do
        locksmith_one.lock do
          raise Exception, "redis lock exception"
        end
      end.to raise_error(Exception, "redis lock exception")

      expect(locksmith_one).not_to be_locked if lock_expiration.nil?
    end

    it "returns the value of the block if block-style locking is used" do
      block_value = locksmith_one.lock do
        42
      end

      expect(block_value).to eq(42)
    end

    it "disappears without a trace when calling `delete!`" do
      locksmith_one.lock
      locksmith_two.delete!

      expect(locksmith_one).not_to be_locked
    end

    context "when lock_timeout is zero" do
      let(:lock_timeout) { 0 }

      it "does not block" do
        did_we_get_in = false

        locksmith_one.lock do
          locksmith_two.lock do
            did_we_get_in = true
          end
        end

        expect(did_we_get_in).to be false
      end

      it "is locked" do
        locksmith_one.lock do
          expect(locksmith_one).to be_locked
        end

        expect(locksmith_one).not_to be_locked if lock_expiration.nil?
      end
    end
  end

  describe "lock with expiration" do
    let(:lock_expiration) { 2 }
    let(:lock_type)       { :while_executing }

    it_behaves_like "a lock"

    context "when lock_type is until_expired" do
      let(:lock_type) { :until_expired }

      it "prevents other processes from locking" do
        locksmith_one.lock

        sleep 1

        expect(locksmith_two.lock).to be_falsey
      end

      it "expires the expected keys" do
        locksmith_one.lock
        locksmith_one.unlock

        expect(locksmith_one).to be_locked
      end
    end

    context "when lock_type is anything else than until_expired" do
      let(:lock_type) { :until_executed }

      it "expires the expected keys" do
        locksmith_one.lock
        expect(locksmith_one).to be_locked
        locksmith_one.unlock
        expect(locksmith_one).to be_locked
        expect(locksmith_one.delete).to eq(nil)

        expect(locksmith_one).to be_locked
      end
    end

    it "deletes the expected keys" do
      locksmith_one.lock
      expect(locksmith_one).to be_locked
      locksmith_one.delete!
      expect(locksmith_one).not_to be_locked
    end

    it "expires keys" do
      locksmith_one.lock
      keys = unique_keys
      expect(unique_keys).not_to include(keys)
    end

    it "expires keys after unlocking" do
      locksmith_one.lock do
        # noop
      end
      keys = unique_keys
      expect { unique_keys }.to eventually_not include(keys)
    end
  end

  # describe 'lock without staleness checking' do
  #   it_behaves_like 'a lock'

  #   it 'can dynamically add resources' do
  #     locksmith_one.lock

  #     3.times do
  #       locksmith_one.unlock
  #     end

  #     expect(locksmith_one.available_count).to eq(4)

  #     locksmith_one.lock(1)
  #     locksmith_one.lock(1)
  #     locksmith_one.lock(1)

  #     expect(locksmith_one.available_count).to eq(1)
  #   end

  #   stale clients and concurrency removed in a0cff5bc42edbe7190d6ede7e7f845074d2d7af6
  #   shared_examples 'can release stale clients' do
  #     # TODO: This spec is flaky and should be improved to not use sleeps
  #     it 'can have stale locks released by a third process', :retry do
  #       watchdog = described_class.new(item_one.merge('stale_client_timeout' => 0.5))
  #       locksmith_one.lock

  #       watchdog.release_stale_locks
  #       expect(locksmith_one).to be_locked

  #       sleep 0.6
  #       watchdog.release_stale_locks

  #       expect(locksmith_one).not_to be_locked
  #     end
  #   end

  #   context 'when redis version < 3.2', redis_ver: '<= 3.2' do
  #     before { allow(SidekiqUniqueJobs).to receive(:redis_version).and_return('3.1') }

  #     it_behaves_like 'can release stale clients'
  #   end

  #   context 'when redis version >= 3.2' do
  #     before { allow(SidekiqUniqueJobs).to receive(:redis_version).and_return('3.2') }

  #     it_behaves_like 'can release stale clients'
  #   end
  # end

  describe "current_time" do
    let(:lock_stale_client_timeout) { 5 }

    before do
      Timecop.freeze(Time.local(1990))
    end

    it "with time support should return a different time than frozen time" do
      expect(locksmith_one.send(:current_time)).not_to eq(Time.now)
    end
  end
end
