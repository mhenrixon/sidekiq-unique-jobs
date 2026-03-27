# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock::UntilAndWhileExecuting, redis_db: 3 do
  let(:process_one)  { described_class.new(item_one, callback) }
  let(:unique)       { :until_and_while_executing }
  let(:queue)        { :another_queue }
  let(:args)         { [sleepy_time] }
  let(:callback)     { -> {} }
  let(:item_one) do
    { "jid" => jid_one,
      "class" => job_class.to_s,
      "queue" => queue,
      "lock" => unique,
      "args" => args,
      "lock_timeout" => lock_timeout }
  end
  let(:item_two) do
    item_one.merge("jid" => jid_two)
  end
  let(:runtime_one) { process_one.send(:runtime_lock) }

  let(:process_two) { described_class.new(item_two, callback) }
  let(:runtime_two) { process_two.send(:runtime_lock) }

  let(:jid_one)      { "jid one" }
  let(:jid_two)      { "jid two" }
  let(:lock_timeout) { nil }
  let(:sleepy_time)  { 0 }

  let(:job_class) { AnotherUniqueJobJob }

  before do
    allow(runtime_one).to receive(:reflect).and_call_original
    allow(runtime_two).to receive(:reflect).and_call_original
    allow(process_one).to receive(:runtime_lock).and_return(runtime_one)
    allow(process_two).to receive(:runtime_lock).and_return(runtime_two)
  end

  it_behaves_like "a lock implementation"

  it "does not manipulate the original item" do
    lock = described_class.new(item_one, callback)
    expect { lock.send(:runtime_lock) }.not_to change { item_one["lock_digest"] }
  end

  it "has not locked runtime_one" do
    process_one.lock
    expect(runtime_one).not_to be_locked
  end

  context "when process_one executes the job" do
    it "releases the lock for process_one" do
      process_one.execute do
        expect(process_one).not_to be_locked
      end
    end

    it "is locked by runtime_one" do
      process_one.execute do
        expect(runtime_one).to be_locked
      end
    end

    it "allows process_two to lock" do
      process_one.execute do
        expect(process_two.lock).to eq(jid_two)
      end
    end

    it "prevents process_two from executing" do
      process_one.lock
      expect { process_two.execute { raise "Hell" } }.not_to raise_error
    end

    it "process two cannot execute the job" do
      process_one.execute do
        process_two.lock
        unset = true
        process_two.execute { unset = false }
        expect(unset).to be(true)
      end
    end

    it "yields without arguments" do
      process_one.lock
      process_one.execute {}
      blk = -> {}

      expect { process_one.execute(&blk) }.not_to raise_error
    end

    context "when client lock has already expired (lock_ttl elapsed)" do
      it "still executes the job via orphaned lock cleanup" do
        process_one.lock

        # Simulate TTL expiry by deleting all lock keys from Redis
        redis do |conn|
          digest = item_one["lock_digest"]
          conn.call("UNLINK", digest, "#{digest}:QUEUED", "#{digest}:PRIMED",
            "#{digest}:LOCKED", "#{digest}:INFO")
          conn.call("ZREM", "uniquejobs:digests", digest)
        end

        expect(process_one).not_to be_locked

        executed = false
        process_one.execute { executed = true }
        expect(executed).to be(true)
      end
    end

    context "when job was enqueued without client middleware (no lock exists)" do
      it "still executes the job" do
        # Don't call process_one.lock — simulate direct Redis enqueue
        executed = false
        process_one.execute { executed = true }
        expect(executed).to be(true)
      end
    end

    context "when multiple jobs are enqueued and executed sequentially" do
      it "executes each job exactly once after the previous completes" do
        results = []

        process_one.lock
        process_one.execute { results << :one }
        expect(results).to eq([:one])

        # After process_one completes, process_two should be able to lock and execute
        process_two.lock
        process_two.execute { results << :two }
        expect(results).to eq([:one, :two])
      end
    end

    context "when worker raises error in runtime lock" do
      before do
        allow(runtime_one.locksmith).to receive(:execute).and_raise(RuntimeError, "Hell")
      end

      it "always unlocks" do
        process_one.lock

        expect { process_one.execute {} }
          .to raise_error(RuntimeError, "Hell")

        expect(process_one).to be_locked
      end
    end
  end
end
