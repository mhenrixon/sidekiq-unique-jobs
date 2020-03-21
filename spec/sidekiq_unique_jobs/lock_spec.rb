# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock do
  subject(:entity) { described_class.new(key) }

  let(:key)    { SidekiqUniqueJobs::Key.new(digest) }
  let(:digest) { "uniquejobs:#{SecureRandom.hex(12)}" }
  let(:job_id) { SecureRandom.hex(12) }
  let(:expected_string) do
    <<~MESSAGE
      Lock status for #{digest}

                value:\s
                 info:\s
          queued_jids: []
          primed_jids: []
          locked_jids: []
           changelogs: []
    MESSAGE
  end

  let(:lock_info) do
    {
      worker: "MyUniqueWorker",
      queue: "queues:custom",
      limit: 5,
      timeout: 10,
      ttl: 2,
      lock: :until_executed,
      unique_args: [1, 2],
      time: SidekiqUniqueJobs.now_f,
    }
  end

  its(:digest)  { is_expected.to be_a(SidekiqUniqueJobs::Redis::String) }
  its(:queued)  { is_expected.to be_a(SidekiqUniqueJobs::Redis::List) }
  its(:primed)  { is_expected.to be_a(SidekiqUniqueJobs::Redis::List) }
  its(:locked)  { is_expected.to be_a(SidekiqUniqueJobs::Redis::Hash) }
  its(:info)    { is_expected.to be_a(SidekiqUniqueJobs::Redis::String) }
  its(:inspect) { is_expected.to eq(expected_string) }
  its(:to_s)    { is_expected.to eq(expected_string) }

  describe ".create" do
    subject(:create) { described_class.create(key, job_id, lock_info) }

    it "creates all expected keys in redis" do
      create
      expect(keys).to match_array([key.digest, key.locked, key.info, key.changelog, key.digests])
      expect(create.locked_jids).to include(job_id)
    end
  end

  describe "#all_jids" do
    subject(:all_jids) { entity.all_jids }

    context "when no locks exist" do
      it { is_expected.to match_array([]) }
    end

    context "when locks exists" do
      before { simulate_lock(key, job_id) }

      it { is_expected.to match_array([job_id]) }
    end
  end

  describe "#lock" do
    subject(:lock) { entity.lock(job_id, lock_info) }

    it "creates keys and adds job_id to locked hash" do
      expect { lock }.to change { entity.locked_jids }.to([job_id])

      expect(keys).to match_array([key.digest, key.locked, key.info, key.changelog, key.digests])
    end
  end

  describe "#del" do
    subject(:del) { lock.del }

    let(:lock) { described_class.create(key, job_id, info) }

    it "creates keys and adds job_id to locked hash" do
      expect { lock }.to change { entity.locked_jids }.to([job_id])
      del
      expect(keys).not_to match_array([key.digest, key.locked, key.info, key.changelog, key.digests])
    end
  end

  describe "#changelogs" do
    subject(:changelogs) { entity.changelogs }

    context "when no changelogs exist" do
      it { is_expected.to match_array([]) }
    end

    context "when changelogs exist" do
      before { simulate_lock(key, job_id) }

      let(:locked_entry) do
        {
          "digest" => digest,
          "job_id" => job_id,
          "message" => "Locked",
          "script" => "lock.lua",
          "time" => kind_of(Float),
        }
      end
      let(:queued_entry) do
        {
          "digest" => digest,
          "job_id" => job_id,
          "message" => "Queued",
          "script" => "queue.lua",
          "time" => kind_of(Float),
        }
      end

      it { is_expected.to match_array([locked_entry, queued_entry]) }
    end
  end
end
