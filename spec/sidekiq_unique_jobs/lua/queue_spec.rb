# frozen_string_literal: true

RSpec.describe "queue.lua" do
  include SidekiqUniqueJobs::Script::Caller
  let(:queue) { call_script(:queue, key.to_a, argv) }

  let(:argv) do
    [
      job_id_one,
      lock_pttl,
      lock_type,
      lock_limit,
    ]
  end
  let(:digest)     { "uniquejobs:digest" }
  let(:key)        { SidekiqUniqueJobs::Key.new(digest) }
  let(:job_id_one) { "job_id_one" }
  let(:job_id_two) { "job_id_two" }
  let(:lock_type)  { :until_executed }
  let(:lock_pttl)  { nil }
  let(:locked_jid) { job_id }
  let(:lock_limit) { 1 }
  let(:now_f)      { SidekiqUniqueJobs.now_f }

  before do
    flush_redis
  end

  context "without previously queued lock" do
    it "stores the right keys in redis" do
      expect { queue }.to change { zcard(key.changelog) }.by(1)

      expect(queue).to eq(job_id_one)
      expect(get(key.digest)).to eq(job_id_one)
      expect(pttl(key.digest)).to eq(-1) # key exists without pttl
      expect(llen(key.queued)).to eq(1)
      expect(exists(key.primed)).to be(false)
      expect(exists(key.locked)).to be(false)
    end

    context "when lock_type is :until_expired" do
      let(:lock_type) { :until_expired }
      let(:lock_pttl) { lock_ttl * 1000 }
      let(:lock_ttl)  { 10 }

      it "stores digest with pexpiration in redis" do
        queue

        expect(ttl(key.digest)).to eq(lock_ttl)
        expect(ttl(key.queued)).to eq(lock_ttl)
      end
    end
  end

  context "when queued by another job_id" do
    before do
      call_script(:queue, key.to_a, [job_id_two, lock_pttl, lock_type, lock_limit])
    end

    context "with lock_limit 1" do
      let(:lock_limit) { 1 }

      it "stores the right keys in redis" do
        expect { queue }.to change { zcard(key.changelog) }.by(1)

        expect(queue).to eq(job_id_two)
        expect(get(key.digest)).to eq(job_id_two)
        expect(pttl(key.digest)).to eq(-1) # key exists without pttl
        expect(llen(key.queued)).to eq(1)
        expect(lrange(key.queued, 0, -1)).to contain_exactly(job_id_two)
        expect(rpop(key.queued)).to eq(job_id_two)
        expect(exists(key.primed)).to be(false)
        expect(exists(key.locked)).to be(false)
      end
    end

    context "with lock_limit 2" do
      let(:lock_limit) { 2 }

      it "stores the right keys in redis" do
        expect { queue }.to change { zcard(key.changelog) }.by(1)

        expect(queue).to eq(job_id_one)
        expect(get(key.digest)).to eq(job_id_one)
        expect(pttl(key.digest)).to eq(-1) # key exists without pttl
        expect(llen(key.queued)).to eq(2)
        expect(lrange(key.queued, 0, -1)).to contain_exactly(job_id_two, job_id_one)
        expect(rpop(key.queued)).to eq(job_id_two)
        expect(exists(key.primed)).to be(false)
        expect(exists(key.locked)).to be(false)
      end
    end
  end

  context "when queued by same job_id" do
    before do
      call_script(:queue, key.to_a, [job_id_one, lock_pttl, lock_type, lock_limit])
    end

    it "stores the right keys in redis" do
      expect { queue }.to change { zcard(key.changelog) }.by(1)

      expect(queue).to eq(job_id_one)
      expect(get(key.digest)).to eq(job_id_one)
      expect(pttl(key.digest)).to eq(-1) # key exists without pttl
      expect(llen(key.queued)).to eq(1)
      expect(lrange(key.queued, 0, -1)).to contain_exactly(job_id_one)
      expect(rpop(key.queued)).to eq(job_id_one)
      expect(exists(key.primed)).to be(false)
      expect(exists(key.locked)).to be(false)
    end
  end

  context "when primed by another job_id" do
    before do
      call_script(:queue, key.to_a, [job_id_two, lock_pttl, lock_type, lock_limit])
      rpoplpush(key.queued, key.primed)
      call_script(:lock, key.to_a, [job_id_two, lock_pttl, lock_type, lock_limit])
    end

    context "with lock_limit 1" do
      it "stores the right keys in redis" do
        expect { queue }.to change { zcard(key.changelog) }.by(1)

        expect(queue).to eq(job_id_two)
        expect(get(key.digest)).to eq(job_id_two)
        expect(llen(key.queued)).to eq(0) # There should be no keys available to be locked
        expect(llen(key.primed)).to eq(0)
        expect(exists(key.locked)).to be(true)
        expect(hexists(key.locked, job_id_two)).to be(1)
        expect(hexists(key.locked, job_id_one)).to be(0)
      end
    end

    context "with lock_limit 2" do
      let(:lock_limit) { 2 }

      it "stores the right keys in redis" do
        expect { queue }.to change { zcard(key.changelog) }.by(1)

        expect(queue).to eq(job_id_one)
        expect(get(key.digest)).to eq(job_id_one)
        expect(llen(key.queued)).to eq(1) # There should be no keys available to be locked
        expect(lrange(key.queued, 0, -1)).to contain_exactly(job_id_one)
        expect(llen(key.primed)).to eq(0)
        expect(exists(key.locked)).to be(true)
        expect(hexists(key.locked, job_id_two)).to be(1)
        expect(hexists(key.locked, job_id_one)).to be(0)
      end
    end
  end
end
