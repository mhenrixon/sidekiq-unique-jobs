# frozen_string_literal: true

require "spec_helper"
RSpec.describe "unlock.lua" do
  subject(:unlock) { call_script(:unlock, key.to_a, argv_one) }

  let(:argv_one)   { [job_id_one, lock_ttl, lock_type, lock_limit] }
  let(:argv_two)   { [job_id_two, lock_ttl, lock_type, lock_limit] }
  let(:job_id_one) { "job_id_one" }
  let(:job_id_two) { "job_id_two" }
  let(:lock_type)  { :until_executed }
  let(:digest)     { "uniquejobs:digest" }
  let(:key)        { SidekiqUniqueJobs::Key.new(digest) }
  let(:redlock)    { SidekiqUniqueJobs::Lock.new(key) }
  let(:queued)     { redlock.queued_list }
  let(:primed)     { redlock.primed_list }
  let(:locked)     { redlock.locked_hash }
  let(:lock_ttl)   { nil }
  let(:locked_jid) { job_id_one }
  let(:lock_limit) { 1 }

  context "when unlocked" do
    it "succeedes without crashing" do
      expect { unlock }.to change { zcard(key.changelog) }.by(1)
      expect(unlock).to eq(job_id_one)
    end
  end

  context "when locked" do
    context "with another job_id" do
      before do
        call_script(:queue, key.to_a, argv_two)
        rpoplpush(key.queued, key.primed)
        call_script(:lock, key.to_a, argv_two)
      end

      it "does not unlock" do
        expect { unlock }.to change { changelogs.count }.by(1)

        expect(queued.count).to be == 0
        expect(primed.count).to be == 0

        expect(locked.count).to be == 1
        expect(locked.entries).to match_array([job_id_two])
        expect(locked[job_id_two].to_f).to be_within(0.5).of(now_f)
      end
    end

    context "with same job_id" do
      before do
        call_script(:queue, key.to_a, argv_one)
        rpoplpush(key.queued, key.primed)
        call_script(:lock, key.to_a, argv_one)
      end

      it "does unlock" do
        expect { unlock }.to change { changelogs.count }.by(1)

        expect { queued.count }.to eventually be == 0
        expect { queued.entries }.to eventually match_array([])

        expect(primed.count).to be == 0

        expect(locked.count).to be == 0
        expect(locked.entries).to match_array([])
        expect(locked[job_id_one]).to be_nil
      end
    end
  end
end
