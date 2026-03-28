# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Fetch::LockAwareUnitOfWork do
  let(:unit_of_work) { described_class.new(inner_work) }
  let(:inner_work) { double("inner_uow", **inner_methods) } # rubocop:disable RSpec/VerifiedDoubles
  let(:inner_methods) do
    {
      queue: "queue:default",
      job: dump_json(job_hash),
      config: nil,
      queue_name: "default",
      acknowledge: nil,
      requeue: nil,
    }
  end

  let(:job_hash) do
    {
      "class" => "MyUniqueJob",
      "jid" => jid,
      "args" => [1, 2],
      "queue" => "default",
      "lock" => "until_executed",
      "lock_digest" => digest,
    }
  end
  let(:jid) { "test-jid-123" }
  let(:digest) { "uniquejobs:test-digest" }

  describe "#acknowledge" do
    context "when lock was already released by middleware" do
      it "calls inner acknowledge without attempting unlock" do
        unit_of_work.acknowledge

        expect(inner_work).to have_received(:acknowledge)
      end
    end

    context "when lock is still held after middleware" do
      let(:lock) { SidekiqUniqueJobs::Lock.new(digest) }
      let(:lock_info) { { type: :until_executed } }

      before { lock.lock(jid, lock_info) }

      it "releases the lock as a safety net" do
        unit_of_work.acknowledge

        expect(inner_work).to have_received(:acknowledge)
        expect(lock.locked_jids).not_to include(jid)
      end
    end

    context "when called twice" do
      it "is idempotent" do
        unit_of_work.acknowledge
        unit_of_work.acknowledge

        expect(inner_work).to have_received(:acknowledge).once
      end
    end

    context "when job is not a unique job" do
      let(:job_hash) do
        { "class" => "RegularJob", "jid" => jid, "args" => [1] }
      end

      it "calls inner acknowledge without lock interaction" do
        unit_of_work.acknowledge

        expect(inner_work).to have_received(:acknowledge)
      end
    end

    context "when lock cleanup raises an error" do
      before do
        allow(SidekiqUniqueJobs::Locksmith).to receive(:new).and_raise(StandardError, "Redis down")
      end

      it "still completes acknowledge without raising" do
        expect { unit_of_work.acknowledge }.not_to raise_error
        expect(inner_work).to have_received(:acknowledge)
      end
    end
  end

  describe "#requeue" do
    it "calls inner requeue" do
      unit_of_work.requeue

      expect(inner_work).to have_received(:requeue)
    end

    context "when job has a lock" do
      let(:lock) { SidekiqUniqueJobs::Lock.new(digest) }
      let(:lock_info) { { type: :until_executed } }

      before { lock.lock(jid, lock_info) }

      it "does NOT release the lock" do
        unit_of_work.requeue

        expect(lock.locked_jids).to include(jid)
      end
    end
  end

  describe "delegation" do
    it "delegates queue to inner work" do
      expect(unit_of_work.queue).to eq("queue:default")
    end

    it "delegates job to inner work" do
      expect(unit_of_work.job).to eq(inner_work.job)
    end

    it "delegates queue_name to inner work" do
      expect(unit_of_work.queue_name).to eq("default")
    end
  end
end
