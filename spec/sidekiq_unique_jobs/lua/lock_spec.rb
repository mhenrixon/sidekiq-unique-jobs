# frozen_string_literal: true

require "spec_helper"
RSpec.describe "lock.lua", redis: :redis do
  subject(:lock) { call_script(:lock, key.to_a, argv_one) }

  let(:argv_one)       { [job_id_one, lock_ttl, lock_type, lock_limit] }
  let(:argv_two)       { [job_id_two, lock_ttl, lock_type, lock_limit] }
  let(:job_id_one)     { "job_id_one" }
  let(:job_id_two)     { "job_id_two" }
  let(:lock_type)      { :until_executed }
  let(:digest)         { "uniquejobs:digest" }
  let(:key)            { SidekiqUniqueJobs::Key.new(digest) }
  let(:redlock)        { SidekiqUniqueJobs::Redis::Lock.new(digest) }
  let(:queued)         { redlock.queued_list }
  let(:primed)         { redlock.primed_list }
  let(:locked)         { redlock.locked_hash }
  let(:lock_ttl)       { nil }
  let(:locked_jid)     { job_id_one }
  let(:current_time)   { SidekiqUniqueJobs::Timing.current_time }
  let(:lock_limit)     { 1 }

  context "when not queued" do
    it "updates Redis correctly" do
      expect { lock }.to change { zcard(key.changelog) }.by(1)

      expect(lock).to eq(job_id_one)

      expect(queued.count).to be == 0
      expect(primed.count).to be == 0

      expect(locked.count).to be == 1
      expect(locked.entries).to match_array([job_id_one])
      expect(locked[job_id_one].to_f).to be_within(0.5).of(current_time)
    end
  end

  context "when queued" do
    before do
      call_script(:queue, key.to_a, argv_one)
    end

    it "updates Redis correctly" do
      expect { lock }.to change { zcard(key.changelog) }.by(1)

      expect(lock).to eq(job_id_one)

      expect(queued.count).to be == 0
      expect(primed.count).to be == 0

      expect(locked.count).to be == 1
      expect(locked.entries).to match_array([job_id_one])
      expect(locked[job_id_one].to_f).to be_within(0.5).of(current_time)
    end
  end

  context "when primed" do
    before do
      call_script(:queue, key.to_a, argv_one)
      rpoplpush(key.queued, key.primed)
    end

    it "updates Redis correctly" do
      expect { lock }.to change { zcard(key.changelog) }.by(1)

      expect(lock).to eq(job_id_one)
      expect(get(key.digest)).to eq(job_id_one)

      expect(queued.count).to be == 0
      expect(primed.count).to be == 0

      expect(locked.count).to be == 1
      expect(locked.entries).to match_array([job_id_one])
      expect(locked[job_id_one].to_f).to be_within(0.5).of(current_time)
    end
  end

  context "when locked by another job" do
    context "with lock_limit 1" do
      before do
        call_script(:queue, key.to_a, argv_two)
        rpoplpush(key.queued, key.primed)
        call_script(:lock, key.to_a, argv_two)
      end

      it "updates Redis correctly" do
        expect { lock }.to change { zcard(key.changelog) }.by(1)

        expect(lock).to eq(nil)
        expect(get(key.digest)).to eq(job_id_two)

        expect(queued.count).to be == 0
        expect(primed.count).to be == 0

        expect(locked.count).to be == 1
        expect(locked.entries).to match_array([job_id_two])
        expect(locked[job_id_two].to_f).to be_within(0.5).of(current_time)
      end
    end

    context "with lock_limit 2" do
      let(:lock_limit) { 2 }

      before do
        call_script(:queue, key.to_a, argv_two)
        rpoplpush(key.queued, key.primed)
        call_script(:lock, key.to_a, argv_two)

        call_script(:queue, key.to_a, argv_one)
        rpoplpush(key.queued, key.primed)
      end

      it "updates Redis correctly" do
        expect { lock }.to change { zcard(key.changelog) }.by(1)

        expect(lock).to eq(job_id_one)
        expect(get(key.digest)).to eq(job_id_one)

        expect(queued.count).to be == 0
        expect(primed.count).to be == 0

        expect(locked.count).to be == 2
        expect(locked.entries).to match_array([job_id_two, job_id_one])
        expect(locked[job_id_two].to_f).to be_within(0.5).of(current_time)
        expect(locked[job_id_one].to_f).to be_within(0.5).of(current_time)
      end
    end
  end

  context "when locked by same job" do
    before do
      call_script(:queue, key.to_a, argv_one)
      rpoplpush(key.queued, key.primed)

      hset(key.locked, job_id_one, current_time)
    end

    it "updates Redis correctly" do
      expect { lock }.to change { zcard(key.changelog) }.by(1)

      expect(lock).to eq(job_id_one)
      expect(get(key.digest)).to eq(job_id_one)

      expect(queued.count).to be == 0
      expect(primed.count).to be == 0

      expect(locked.count).to be == 1
      expect(locked.entries).to match_array([job_id_one])
      expect(locked[job_id_one].to_f).to be_within(0.5).of(current_time)
    end
  end
end