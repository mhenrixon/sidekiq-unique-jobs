# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Changelog do
  let(:entity) { described_class.new }
  let(:digest) { "uniquejobs:#{SecureRandom.hex(12)}" }
  let(:key)    { SidekiqUniqueJobs::Key.new(digest) }
  let(:job_id) { SecureRandom.hex(12) }

  describe "#add" do
    subject(:add) { entity.add(**entry) }

    let(:entry) do
      {
        message: "Added from test",
        job_id: job_id,
        digest: digest,
        script: __FILE__.to_s,
      }
    end

    it "adds a new entry" do
      expect { add }.to change { entity.entries.size }.by(1)
      expect(add).to eq(true)
    end
  end

  describe "#clear" do
    subject(:clear) { entity.clear }

    context "with entries" do
      before do
        entity.add(
          message: "Added from test",
          job_id: job_id,
          digest: digest,
          script: __FILE__.to_s,
        )
      end

      it "clears out all entries" do
        expect { clear }.to change { entity.entries.size }.by(-1)
        expect(clear).to be == 1
      end
    end

    context "without entries" do
      it "returns 0 (zero)" do
        expect { clear }.not_to change { entity.entries.size }
        expect(clear).to be == 0
      end
    end
  end

  describe "#exist?" do
    subject(:exist?) { entity.exist? }

    context "when no entries exist" do
      it { is_expected.to be == false }
    end

    context "when entries exist" do
      before { simulate_lock(key, job_id) }

      it { is_expected.to be == true }
    end
  end

  describe "#pttl" do
    subject(:pttl) { entity.pttl }

    context "when no entries exist" do
      it { is_expected.to be == -2 }
    end

    context "when entries exist without expiration" do
      before { simulate_lock(key, job_id) }

      it { is_expected.to be == -1 }
    end

    context "when entries exist with expiration" do
      before do
        simulate_lock(key, job_id)
        pexpire(key.changelog, 600)
      end

      it { is_expected.to be_within(20).of(600) }
    end
  end

  describe "#ttl" do
    subject(:ttl) { entity.ttl }

    context "when no entries exist" do
      it { is_expected.to be == -2 }
    end

    context "when entries exist without expiration" do
      before { simulate_lock(key, job_id) }

      it { is_expected.to be == -1 }
    end

    context "when entries exist with expiration" do
      before do
        simulate_lock(key, job_id)
        expire(key.changelog, 600)
      end

      it { is_expected.to be == 600 }
    end
  end

  describe "#expires?" do
    subject(:expires?) { entity.expires? }

    context "when no entries exist" do
      it { is_expected.to be == false }
    end

    context "when entries exist" do
      before do
        simulate_lock(key, job_id)
        expire(key.changelog, 600)
      end

      it { is_expected.to be == true }
    end
  end

  describe "#count" do
    subject(:count) { entity.count }

    context "when no entries exist" do
      it { is_expected.to be == 0 }
    end

    context "when entries exist" do
      before { simulate_lock(key, job_id) }

      it { is_expected.to be == 2 }
    end
  end

  describe "#entries" do
    subject(:entries) { entity.entries(pattern: pattern, count: count) }

    let(:pattern) { "*" }
    let(:count)   { nil }

    context "when no entries exist" do
      it { is_expected.to match_array([]) }
    end

    context "when entries exist" do
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

      context "when given count 1" do
        let(:count) { 1 }

        # count only is considered per iteration, this would have iterated twice
        it { is_expected.to match_array([locked_entry, queued_entry]) }
      end
    end
  end

  describe "#page" do
    subject(:page) { entity.page(cursor: cursor, pattern: pattern, page_size: page_size) }

    let(:cursor)    { 0 }
    let(:pattern)   { "*" }
    let(:page_size) { 1 }

    context "when no entries exist" do
      it { is_expected.to match_array([0, 0, []]) }
    end

    context "when entries exist" do
      before do
        flush_redis
        simulate_lock(key, job_id)
      end

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

      it { is_expected.to match_array([2, anything, a_collection_including(kind_of(Hash))]) }
    end
  end
end
