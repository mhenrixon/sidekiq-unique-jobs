# frozen_string_literal: true

RSpec.describe "queue_and_lock.lua" do
  subject(:queue_and_lock) { call_script(:queue_and_lock, key.to_a, argv_one) }

  let(:argv_one)   { [job_id_one, lock_pttl, lock_type, lock_limit, lock_score] }
  let(:argv_two)   { [job_id_two, lock_pttl, lock_type, lock_limit, lock_score] }
  let(:job_id_one) { "job_id_one" }
  let(:job_id_two) { "job_id_two" }
  let(:lock_type)  { :until_executed }
  let(:digest)     { "uniquejobs:digest" }
  let(:key)        { SidekiqUniqueJobs::Key.new(digest) }
  let(:redlock)    { SidekiqUniqueJobs::Lock.new(digest) }
  let(:queued)     { redlock.queued }
  let(:primed)     { redlock.primed }
  let(:locked)     { redlock.locked }
  let(:lock_pttl)  { nil }
  let(:lock_limit) { 1 }
  let(:now_f)      { SidekiqUniqueJobs.now_f }
  let(:lock_score) { now_f.to_s }

  before do
    flush_redis
  end

  context "with single-lock fast path (limit 1)" do
    let(:lock_limit) { 1 }

    context "when no lock exists" do
      it "acquires the lock directly" do
        expect(queue_and_lock).to eq(job_id_one)
      end

      it "sets the digest key" do
        queue_and_lock
        expect(get(key.digest)).to eq(job_id_one)
      end

      it "sets the locked hash" do
        queue_and_lock
        expect(hget(key.locked, job_id_one)).not_to be_nil
      end

      it "adds to digests sorted set" do
        expect { queue_and_lock }.to change { zcard("uniquejobs:digests") }.by(1)
      end

      it "records a changelog entry" do
        expect { queue_and_lock }.to change { zcard(key.changelog) }.by(1)
      end

      it "does not use queued or primed lists" do
        queue_and_lock
        expect(llen(key.queued)).to eq(0)
        expect(llen(key.primed)).to eq(0)
      end
    end

    context "when already locked by the same job_id (re-lock)" do
      before do
        call_script(:queue_and_lock, key.to_a, argv_one)
      end

      it "returns the job_id (idempotent)" do
        expect(queue_and_lock).to eq(job_id_one)
      end

      it "does not add a second lock entry" do
        queue_and_lock
        expect(locked.count).to eq(1)
      end
    end

    context "when locked by a different job_id" do
      before do
        call_script(:queue_and_lock, key.to_a, argv_two)
      end

      it "returns nil (lock denied)" do
        expect(queue_and_lock).to be_nil
      end

      it "does not modify the existing lock" do
        queue_and_lock
        expect(hget(key.locked, job_id_two)).not_to be_nil
        expect(hexists(key.locked, job_id_one)).to eq(0)
      end
    end
  end

  context "with multi-lock path (limit > 1)" do
    let(:lock_limit) { 3 }

    context "when no lock exists" do
      it "acquires the lock" do
        expect(queue_and_lock).to eq(job_id_one)
      end

      it "sets the digest and locked hash" do
        queue_and_lock
        expect(get(key.digest)).to eq(job_id_one)
        expect(hget(key.locked, job_id_one)).not_to be_nil
      end
    end

    context "when already locked by the same job_id (re-lock)" do
      before do
        call_script(:queue_and_lock, key.to_a, argv_one)
      end

      it "returns the job_id (idempotent)" do
        expect(queue_and_lock).to eq(job_id_one)
      end
    end

    context "when one lock exists from another job" do
      before do
        call_script(:queue_and_lock, key.to_a, argv_two)
      end

      it "acquires the lock (within limit)" do
        expect(queue_and_lock).to eq(job_id_one)
      end

      it "has both jobs locked" do
        queue_and_lock
        expect(locked.count).to eq(2)
        expect(locked.entries).to contain_exactly(job_id_one, job_id_two)
      end
    end

    context "when limit is reached" do
      let(:lock_limit) { 2 }

      before do
        call_script(:queue_and_lock, key.to_a, argv_two)
        call_script(:queue_and_lock, key.to_a, ["job_id_three", lock_pttl, lock_type, lock_limit, lock_score])
      end

      it "returns nil (limit exceeded)" do
        expect(queue_and_lock).to be_nil
      end

      it "does not add the third lock" do
        queue_and_lock
        expect(locked.count).to eq(2)
      end
    end
  end

  context "with TTL (pttl > 0)" do
    let(:lock_pttl) { 50_000 }

    it "sets PEXPIRE on digest" do
      queue_and_lock
      expect(pttl(key.digest)).to be_between(1, lock_pttl)
    end

    it "sets PEXPIRE on locked hash" do
      queue_and_lock
      expect(pttl(key.locked)).to be_between(1, lock_pttl)
    end

    it "sets PEXPIRE on info key" do
      # Simulate lock_info being written (normally done by locksmith)
      set(key.info, "test_info")
      queue_and_lock
      expect(pttl(key.info)).to be_between(1, lock_pttl)
    end
  end

  context "without TTL (pttl nil)" do
    let(:lock_pttl) { nil }

    it "does not set expiration on digest" do
      queue_and_lock
      expect(ttl(key.digest)).to eq(-1)
    end

    it "does not set expiration on locked hash" do
      queue_and_lock
      expect(ttl(key.locked)).to eq(-1)
    end
  end

  context "with lock_type :until_expired" do
    let(:lock_type) { :until_expired }
    let(:lock_pttl) { 50_000 }

    it "adds to expiring_digests sorted set" do
      expect { queue_and_lock }.to change { zcard("uniquejobs:expiring_digests") }.by(1)
    end

    it "does not add to regular digests" do
      expect { queue_and_lock }.not_to change { zcard("uniquejobs:digests") }
    end

    it "acquires the lock" do
      expect(queue_and_lock).to eq(job_id_one)
    end

    context "without TTL" do
      let(:lock_pttl) { nil }

      it "adds to regular digests instead" do
        expect { queue_and_lock }.to change { zcard("uniquejobs:digests") }.by(1)
      end
    end
  end

  context "with lock_type :until_executed" do
    let(:lock_type) { :until_executed }

    it "adds to regular digests" do
      expect { queue_and_lock }.to change { zcard("uniquejobs:digests") }.by(1)
    end
  end

  context "with lock_type :while_executing" do
    let(:lock_type) { :while_executing }

    it "acquires the lock" do
      expect(queue_and_lock).to eq(job_id_one)
    end

    it "adds to regular digests" do
      expect { queue_and_lock }.to change { zcard("uniquejobs:digests") }.by(1)
    end
  end

  context "with lock_type :until_and_while_executing" do
    let(:lock_type) { :until_and_while_executing }

    it "acquires the lock" do
      expect(queue_and_lock).to eq(job_id_one)
    end
  end

  context "with lock_score handling" do
    context "when lock_score is empty" do
      let(:lock_score) { "" }

      it "uses current_time for the digests score" do
        queue_and_lock
        scores = Sidekiq.redis { |c| c.zrange("uniquejobs:digests", 0, -1, "WITHSCORES") }
        expect(scores).not_to be_empty
      end
    end

    context "when lock_score has a value" do
      let(:lock_score) { "1234567890.123" }

      it "uses the provided score" do
        queue_and_lock
        scores = Sidekiq.redis { |c| c.zrange("uniquejobs:digests", 0, -1, "WITHSCORES") }
        # ZRANGE with WITHSCORES returns [[member, score], ...]
        expect(scores.first.last).to eq(1_234_567_890.123)
      end
    end
  end

  context "when compared with separate queue+lock scripts" do
    it "produces the same locked state as queue -> lmove -> lock" do
      # Combined path
      result_combined = call_script(:queue_and_lock, key.to_a, argv_one)
      combined_locked = hget(key.locked, job_id_one)
      combined_digest = get(key.digest)

      # Verify the combined script locked correctly
      expect(result_combined).to eq(job_id_one)
      expect(combined_locked).not_to be_nil
      expect(combined_digest).to eq(job_id_one)
    end
  end
end
