# frozen_string_literal: true

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
  let(:queued)     { redlock.queued }
  let(:primed)     { redlock.primed }
  let(:locked)     { redlock.locked }
  let(:lock_ttl)   { nil }
  let(:locked_jid) { job_id_one }
  let(:lock_limit) { 1 }

  shared_context "with a lock", with_a_lock: true do
    before do
      call_script(:queue, key.to_a, argv_one)
      rpoplpush(key.queued, key.primed)
      call_script(:lock, key.to_a, argv_one)
    end
  end

  shared_context "with another lock", :with_another_lock do
    before do
      call_script(:queue, key.to_a, argv_two)
      rpoplpush(key.queued, key.primed)
      call_script(:lock, key.to_a, argv_two)
    end
  end

  shared_examples "unlock with ttl" do
    it { expect { unlock }.to change { unique_keys }.to(%w[uniquejobs:digest:QUEUED]) }
    it { expect { unlock }.to change { llen(key.queued) }.by(1) }

    it { expect { unlock }.to change { llen(key.primed) }.by(0) }

    it { expect { unlock }.to change { ttl(key.locked) }.to(-2) }
    it { expect { unlock }.to change { hget(key.locked, job_id_one) }.to(nil) }

    it { expect { unlock }.to change { ttl(key.digest) }.to(-2) }
    it { expect { unlock }.to change { zcard(key.digests) }.by(-1) }
    it { expect { unlock }.to change { digests.entries }.from(key.digest => kind_of(Float)).to({}) }

    it { expect { unlock }.to change { zcard(key.changelog) }.by(1) }
  end

  shared_examples "unlock without ttl" do
    it { expect { unlock }.to change { unique_keys }.to(%w[uniquejobs:digest:QUEUED]) }
    it { expect { unlock }.to change { lrange(key.queued, -1, 0) }.to(["1"]) }
    it { expect { unlock }.to change { llen(key.queued) }.by(1) }

    it { expect { unlock }.to change { llen(key.primed) }.by(0) }

    it { expect { unlock }.to change { ttl(key.locked) }.to(-2) }
    it { expect { unlock }.to change { hget(key.locked, job_id_one) }.to(nil) }

    it { expect { unlock }.to change { ttl(key.digest) }.from(-1).to(-2) }
    it { expect { unlock }.to change { zcard(key.digests) }.by(-1) }
    it { expect { unlock }.to change { digests.entries }.from(key.digest => kind_of(Float)).to({}) }

    it { expect { unlock }.to change { zcard(key.changelog) }.by(1) }
  end

  context "with lock: :until_expired", :with_a_lock do
    let(:lock_type) { :until_expired }

    context "when given lock_ttl 50_000" do
      let(:lock_ttl) { 50_000 }

      it { expect { unlock }.to change { zcard(key.changelog) }.by(1) }
      it { expect { unlock }.not_to change { ttl(key.digest) } }
      it { expect { unlock }.to change { llen(key.queued) }.by(1) }
      it { expect { unlock }.to change { llen(key.primed) }.by(0) }
      it { expect { unlock }.not_to change { ttl(key.locked) } }
      it { expect { unlock }.not_to change { hget(key.locked, job_id_one) } }
      it { expect { unlock }.not_to change { zcard(key.expiring_digests) } }
    end

    context "when given lock_ttl nil" do
      let(:lock_ttl) { nil }

      it { expect { unlock }.to change { zcard(key.changelog) }.by(1) }
      it { expect { unlock }.not_to change { ttl(key.digest) } }
      it { expect { unlock }.to change { lrange(key.queued, -1, 0) }.to(["1"]) }
      it { expect { unlock }.to change { llen(key.queued) }.by(1) }
      it { expect { unlock }.to change { llen(key.primed) }.by(0) }
      it { expect { unlock }.not_to change { ttl(key.locked) } }
      it { expect { unlock }.not_to change { hget(key.locked, job_id_one) } }
      it { expect { unlock }.to change { zcard(key.digests) }.by(-1) }
    end
  end

  context "with lock: :until_executed", :with_a_lock do
    let(:lock_type) { :until_executed }

    context "when given lock_ttl 50_000" do
      let(:lock_ttl) { 50_000 }

      it_behaves_like "unlock with ttl"
    end

    context "when given lock_ttl nil" do
      let(:lock_ttl) { nil }

      it_behaves_like "unlock without ttl"
    end
  end

  context "with lock: :until_executing", :with_a_lock do
    let(:lock_type) { :until_executing }

    context "when given lock_ttl 50_000" do
      let(:lock_ttl) { 50_000 }

      it_behaves_like "unlock with ttl"
    end

    context "when given lock_ttl nil" do
      let(:lock_ttl) { nil }

      it_behaves_like "unlock without ttl"
    end
  end

  context "with lock: :until_and_while_executing", :with_a_lock do
    let(:lock_type) { :until_and_while_executing }

    context "when given lock_ttl 50_000" do
      let(:lock_ttl) { 50_000 }

      it_behaves_like "unlock with ttl"
    end

    context "when given lock_ttl nil" do
      let(:lock_ttl) { nil }

      it_behaves_like "unlock without ttl"
    end
  end

  context "with lock: :while_executing", :with_a_lock do
    let(:lock_type) { :while_executing }

    context "when given lock_ttl 50_000" do
      let(:lock_ttl) { 50_000 }

      it_behaves_like "unlock with ttl"
    end

    context "when given lock_ttl nil" do
      let(:lock_ttl) { nil }

      it_behaves_like "unlock without ttl"
    end
  end

  context "when unlocked" do
    it "succeedes without crashing" do
      expect { unlock }.to change { zcard(key.changelog) }.by(1)
      expect(unlock).to eq(job_id_one)
    end
  end

  context "when locked" do
    context "with another job_id", :with_another_lock do
      it "does not unlock" do
        expect { unlock }.to change { changelogs.count }.by(1)

        expect(queued.count).to be == 0
        expect(primed.count).to be == 0

        expect(locked.count).to be == 1
        expect(locked.entries).to match_array([job_id_two])
        expect(locked[job_id_two].to_f).to be_within(0.5).of(now_f)
      end
    end

    context "with same job_id", :with_a_lock do
      it "does unlock" do
        expect { unlock }.to change { changelogs.count }.by(1)
                                                        .and change { digests.count }.by(-1)

        expect(queued.count).to eq(1)
        expect(queued.entries).to match_array(["1"])

        expect(primed.count).to be == 0

        expect(locked.count).to be == 0
        expect(locked.entries).to match_array([])
        expect(locked[job_id_one]).to be_nil
      end
    end

    context "when lock_limit > 1", :with_a_lock, :with_another_lock do
      let(:lock_limit) { 2 }

      it { expect { unlock }.not_to change { digests.count }.from(1) }
    end
  end
end
