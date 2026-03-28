# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock do
  let(:digest)    { "uniquejobs:#{SecureRandom.hex(12)}" }
  let(:job_id)    { "test-jid-#{SecureRandom.hex(6)}" }
  let(:lock_info) { { "type" => "until_executed", "worker" => "MyUniqueJob" } }

  describe ".create" do
    it "creates a lock and returns a Lock instance" do
      lock = described_class.create(digest, job_id, lock_info: lock_info)

      expect(lock).to be_a(described_class)
      expect(lock.locked_jids).to include(job_id)
    end
  end

  describe "#lock" do
    subject(:lock) { described_class.new(digest) }

    it "creates the LOCKED hash and adds to digests ZSET" do
      lock.lock(job_id, lock_info)

      expect(lock.locked_jids).to include(job_id)

      redis do |conn|
        expect(conn.call("ZSCORE", "uniquejobs:digests", digest)).not_to be_nil
      end
    end

    it "stores metadata as JSON in the LOCKED hash value" do
      lock.lock(job_id, lock_info)

      redis do |conn|
        raw = conn.call("HGET", "#{digest}:LOCKED", job_id)
        parsed = JSON.parse(raw)
        expect(parsed).to include("type" => "until_executed", "worker" => "MyUniqueJob")
      end
    end
  end

  describe "#unlock" do
    subject(:lock) { described_class.new(digest) }

    it "removes the job_id from the LOCKED hash" do
      lock.lock(job_id, lock_info)
      expect(lock.locked_jids).to include(job_id)

      lock.unlock(job_id)
      expect(lock.locked_jids).not_to include(job_id)
    end
  end

  describe "#del" do
    subject(:lock) { described_class.new(digest) }

    it "removes LOCKED hash and digests entry" do
      lock.lock(job_id, lock_info)
      lock.del

      redis do |conn|
        expect(conn.call("EXISTS", "#{digest}:LOCKED")).to eq(0)
        expect(conn.call("ZSCORE", "uniquejobs:digests", digest)).to be_nil
      end
    end
  end

  describe "#info" do
    subject(:lock) { described_class.new(digest) }

    context "when lock exists" do
      before { lock.lock(job_id, lock_info) }

      it "returns metadata from LOCKED hash" do
        expect(lock.info.value).to include("type" => "until_executed")
      end

      it "supports hash-like access" do
        expect(lock.info["worker"]).to eq("MyUniqueJob")
      end
    end

    context "when lock does not exist" do
      it "returns empty info" do
        expect(lock.info.value).to eq({})
      end
    end
  end

  describe "#created_at" do
    subject(:lock) { described_class.new(digest) }

    it "returns the timestamp from lock metadata" do
      lock.lock(job_id, lock_info)
      expect(lock.created_at).to be_a(Float)
      expect(lock.created_at).to be_positive
    end
  end

  describe "#locked_jids" do
    subject(:lock) { described_class.new(digest) }

    before { lock.lock(job_id, lock_info) }

    context "without values" do
      it "returns array of job IDs" do
        expect(lock.locked_jids).to include(job_id)
      end
    end

    context "with values" do
      it "returns hash of job_id => metadata" do
        result = lock.locked_jids(with_values: true)
        expect(result).to be_a(Hash)
        expect(result.keys).to include(job_id)
      end
    end
  end

  describe "#to_s" do
    it "returns a compact string" do
      lock = described_class.new(digest)
      expect(lock.to_s).to eq("Lock(#{digest})")
    end
  end
end
