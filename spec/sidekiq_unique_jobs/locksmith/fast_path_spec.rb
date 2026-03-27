# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Locksmith do # rubocop:disable RSpec/SpecFilePathFormat
  let(:locksmith_one) { described_class.new(item_one) }
  let(:locksmith_two) { described_class.new(item_two) }

  let(:jid_one)      { "fast_path_jid_one" }
  let(:jid_two)      { "fast_path_jid_two" }
  let(:lock_timeout) { 0 }
  let(:lock_limit)   { 1 }
  let(:lock_ttl)     { nil }
  let(:lock_args)    { [] }
  let(:queue)        { "default" }
  let(:digest)       { "uniquejobs:fast_path_test" }
  let(:key)          { SidekiqUniqueJobs::Key.new(digest) }

  let(:item_one) do
    {
      "class" => worker_class,
      "jid" => jid_one,
      "lock" => lock_type.to_s,
      "lock_args" => lock_args,
      "lock_digest" => digest,
      "lock_limit" => lock_limit,
      "lock_timeout" => lock_timeout,
      "lock_ttl" => lock_ttl,
      "queue" => queue,
    }
  end

  let(:item_two) { item_one.merge("jid" => jid_two) }

  shared_examples "fast path lock acquisition" do
    it "acquires the lock" do
      expect(locksmith_one.lock).to eq(jid_one)
      expect(locksmith_one).to be_locked
    end

    it "prevents duplicate locks" do
      locksmith_one.lock
      expect(locksmith_two.lock).to be_falsey
    end

    it "unlocks correctly" do
      locksmith_one.lock
      locksmith_one.unlock
      expect(locksmith_one).not_to be_locked if lock_ttl.nil?
    end

    it "uses the sync path (sync_locked = true)" do
      locksmith_one.lock
      argv = locksmith_one.send(:unlock_argv)
      expect(argv.last).to eq(1)
    end

    it "does not use queued or primed lists" do
      locksmith_one.lock
      Sidekiq.redis do |conn|
        expect(conn.llen(key.queued)).to eq(0)
        expect(conn.llen(key.primed)).to eq(0)
      end
    end

    it "allows re-locking by the same job" do
      locksmith_one.lock
      expect(locksmith_one.lock).to eq(jid_one)
    end
  end

  context "with lock: :until_executed" do
    let(:lock_type) { :until_executed }
    let(:worker_class) { "UntilExecutedJob" }

    it_behaves_like "fast path lock acquisition"

    it "unlocks correctly after lock + unlock" do
      locksmith_one.lock
      expect(locksmith_one).to be_locked
      locksmith_one.unlock
      expect(locksmith_one).not_to be_locked
    end
  end

  context "with lock: :until_executing" do
    let(:lock_type) { :until_executing }
    let(:worker_class) { "UntilExecutedJob" }

    it_behaves_like "fast path lock acquisition"
  end

  context "with lock: :until_expired" do
    let(:lock_type) { :until_expired }
    let(:lock_ttl)  { 60 } # seconds; pttl will be 60_000 ms
    let(:worker_class) { "UntilExecutedJob" }

    it "acquires the lock" do
      expect(locksmith_one.lock).to eq(jid_one)
      expect(locksmith_one).to be_locked
    end

    it "prevents duplicate locks" do
      locksmith_one.lock
      expect(locksmith_two.lock).to be_falsey
    end

    it "tracks in expiring_digests" do
      locksmith_one.lock
      Sidekiq.redis do |conn|
        count = conn.zcard("uniquejobs:expiring_digests")
        expect(count).to be >= 1
      end
    end

    it "sets TTL on lock keys" do
      locksmith_one.lock
      Sidekiq.redis do |conn|
        # lock_ttl is seconds, pttl is in milliseconds
        expect(conn.pttl(key.locked)).to be_between(1, lock_ttl * 1_000)
      end
    end

    it "remains locked after unlock attempt" do
      locksmith_one.lock
      locksmith_one.unlock
      expect(locksmith_one).to be_locked
    end
  end

  context "with lock: :while_executing" do
    let(:lock_type) { :while_executing }
    let(:worker_class) { "UntilExecutedJob" }

    it_behaves_like "fast path lock acquisition"
  end

  context "with lock: :until_and_while_executing" do
    let(:lock_type) { :until_and_while_executing }
    let(:worker_class) { "UntilExecutedJob" }

    it_behaves_like "fast path lock acquisition"
  end

  context "with lock_limit > 1" do
    let(:lock_type) { :until_executed }
    let(:lock_limit) { 3 }
    let(:worker_class) { "UntilExecutedJob" }

    it "allows multiple concurrent locks" do
      locksmith_one.lock
      locksmith_two.lock

      expect(locksmith_one).to be_locked
      expect(locksmith_two).to be_locked
    end

    it "respects the limit" do
      locksmith_one.lock
      locksmith_two.lock

      third = described_class.new(item_one.merge("jid" => "jid_three"))
      third.lock

      fourth = described_class.new(item_one.merge("jid" => "jid_four"))
      expect(fourth.lock).to be_falsey
    end

    it "uses the sync path for lock_limit > 1 with lock_timeout 0" do
      locksmith_one.lock
      argv = locksmith_one.send(:unlock_argv)
      expect(argv.last).to eq(1)
    end
  end

  context "with lock_ttl" do
    let(:lock_type) { :until_executed }
    let(:lock_ttl) { 30 } # seconds; pttl will be 30_000 ms
    let(:worker_class) { "UntilExecutedJob" }

    it "sets PEXPIRE on locked hash" do
      locksmith_one.lock
      Sidekiq.redis do |conn|
        pttl_val = conn.pttl(key.locked)
        expect(pttl_val).to be_between(1, lock_ttl * 1_000)
      end
    end

    it "sets PEXPIRE on digest key" do
      locksmith_one.lock
      Sidekiq.redis do |conn|
        pttl_val = conn.pttl(key.digest)
        expect(pttl_val).to be_between(1, lock_ttl * 1_000)
      end
    end
  end

  context "with blocking path (execute method)" do
    let(:lock_type) { :until_executed }
    let(:worker_class) { "UntilExecutedJob" }

    it "does not use sync path" do
      locksmith_one.execute { "work" }
      # execute uses primed_async, which goes through the blocking path
      # sync_locked should remain false
      argv = locksmith_one.send(:unlock_argv)
      expect(argv.last).to eq(0)
    end

    it "executes the block" do
      result = locksmith_one.execute { 42 }
      expect(result).to eq(42)
    end
  end

  context "with wait parameter (blocking path)" do
    let(:lock_type) { :until_executed }
    let(:worker_class) { "UntilExecutedJob" }
    let(:lock_timeout) { 1 }

    it "uses the blocking path, not lock_sync!" do
      locksmith_one.lock(wait: 1)
      # When wait is provided, it should use the blocking path
      # which doesn't set sync_locked
      argv = locksmith_one.send(:unlock_argv)
      expect(argv.last).to eq(0)
    end
  end
end
