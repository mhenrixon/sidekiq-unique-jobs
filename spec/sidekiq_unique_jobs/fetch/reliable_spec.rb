# frozen_string_literal: true

require "sidekiq/fetch"

RSpec.describe SidekiqUniqueJobs::Fetch::Reliable do
  let(:identity) { "#{Socket.gethostname}:#{Process.pid}" }
  let(:working_key) { SidekiqUniqueJobs::Key.working(identity) }
  let(:heartbeat_key) { SidekiqUniqueJobs::Key.heartbeat(identity) }
  let(:queue_name) { "reliable_test" }
  let(:queue_key) { "queue:#{queue_name}" }

  let(:job_hash) do
    {
      "class" => "MyUniqueJob",
      "jid" => "reliable-test-jid",
      "queue" => queue_name,
      "args" => [1, 2],
      "lock" => "until_executed",
      "lock_digest" => "uniquejobs:reliable-test-digest",
    }
  end
  let(:job_json) { dump_json(job_hash) }

  # We can't easily instantiate the full fetch (it starts threads),
  # so test the UnitOfWork and key patterns directly.

  describe SidekiqUniqueJobs::Fetch::Reliable::UnitOfWork do
    let(:uow) { described_class.new(queue_key, job_json, nil, working_key) }

    before do
      # Simulate: job is in working list (as if LMOVE put it there)
      redis { |conn| conn.call("LPUSH", working_key, job_json) }
    end

    describe "#queue_name" do
      it "strips the queue: prefix" do
        expect(uow.queue_name).to eq(queue_name)
      end
    end

    describe "#acknowledge" do
      context "when job has a lock" do
        let(:lock) { SidekiqUniqueJobs::Lock.new(job_hash["lock_digest"]) }
        let(:lock_info) { { type: :until_executed } }

        before { lock.lock(job_hash["jid"], lock_info) }

        it "removes from working list and unlocks" do
          uow.acknowledge

          redis do |conn|
            expect(conn.call("LLEN", working_key)).to eq(0)
          end
          expect(lock.locked_jids).not_to include(job_hash["jid"])
        end
      end

      context "when job is not a unique job" do
        let(:job_hash) { { "class" => "RegularJob", "jid" => "abc", "args" => [] } }

        it "removes from working list without error" do
          uow.acknowledge

          redis do |conn|
            expect(conn.call("LLEN", working_key)).to eq(0)
          end
        end
      end
    end

    describe "#requeue" do
      it "moves job back to queue and removes from working list" do
        uow.requeue

        redis do |conn|
          expect(conn.call("LLEN", working_key)).to eq(0)
          expect(conn.call("LLEN", queue_key)).to eq(1)
        end
      end

      context "when job has a lock" do
        let(:lock) { SidekiqUniqueJobs::Lock.new(job_hash["lock_digest"]) }
        let(:lock_info) { { type: :until_executed } }

        before { lock.lock(job_hash["jid"], lock_info) }

        it "preserves the lock" do
          uow.requeue

          expect(lock.locked_jids).to include(job_hash["jid"])
        end
      end
    end
  end

  describe "Key.working" do
    it "returns a uniquejobs-namespaced key" do
      expect(working_key).to start_with("uniquejobs:working:")
      expect(working_key).to include(identity)
    end
  end

  describe "Key.heartbeat" do
    it "returns a uniquejobs-namespaced key" do
      expect(heartbeat_key).to start_with("uniquejobs:heartbeat:")
      expect(heartbeat_key).to include(identity)
    end
  end

  describe "lock validation at fetch" do
    it "returns lock_valid=0 when LOCKED hash does not exist" do
      redis { |conn| conn.call("LPUSH", queue_key, job_json) }

      result = SidekiqUniqueJobs::Script::Caller.call_script(
        :fetch,
        [queue_key, working_key],
        [],
      )

      job, lock_valid = result
      expect(job).not_to be_nil
      expect(lock_valid).to eq(0)
    end

    it "returns lock_valid=1 when LOCKED hash contains the JID" do
      digest = job_hash["lock_digest"]
      jid = job_hash["jid"]

      redis do |conn|
        conn.call("LPUSH", queue_key, job_json)
        conn.call("HSET", "#{digest}:LOCKED", jid, '{"type":"until_executed"}')
      end

      result = SidekiqUniqueJobs::Script::Caller.call_script(
        :fetch,
        [queue_key, working_key],
        [],
      )

      job, lock_valid = result
      expect(job).not_to be_nil
      expect(lock_valid).to eq(1)
    end

    it "always delivers the job regardless of lock_valid" do
      # Job with no lock — should still be fetched
      redis { |conn| conn.call("LPUSH", queue_key, job_json) }

      result = SidekiqUniqueJobs::Script::Caller.call_script(
        :fetch,
        [queue_key, working_key],
        [],
      )

      job, _lock_valid = result
      expect(job).not_to be_nil
      expect(JSON.parse(job)["jid"]).to eq(job_hash["jid"])
    end
  end

  describe "orphan recovery" do
    let(:dead_identity) { "dead-host:99999" }
    let(:dead_working_key) { SidekiqUniqueJobs::Key.working(dead_identity) }

    it "requeues jobs from dead process working lists" do
      # Simulate: dead process left a job in its working list
      redis do |conn|
        conn.call("LPUSH", dead_working_key, job_json)
        # No heartbeat for dead process
      end

      expect(redis { |conn| conn.call("LLEN", dead_working_key) }).to eq(1)
      expect(redis { |conn| conn.call("LLEN", queue_key) }).to eq(0)

      # Recovery should move job back to queue
      # We test the recovery logic directly since instantiating the fetch starts threads
      described_class.new(
        instance_double(Sidekiq::Capsule,
          config: {},
          queues: [queue_name],
          mode: :strict,
          weights: {}).tap { |c| allow(c).to receive(:[]).and_return(nil) },
      )

      # Give heartbeat thread a moment to start, then check recovery
      expect(redis { |conn| conn.call("LLEN", dead_working_key) }).to eq(0)
      expect(redis { |conn| conn.call("LLEN", queue_key) }).to eq(1)
    end
  end
end
