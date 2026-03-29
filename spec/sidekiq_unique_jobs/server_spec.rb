# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Server do
  describe ".configure" do
    subject(:configure) { described_class.configure(config) }

    let(:config) { Sidekiq.default_configuration }

    before do
      allow(config).to receive(:on).with(:startup).and_call_original
      allow(config).to receive(:on).with(:shutdown).and_call_original
      allow(config.death_handlers).to receive(:<<).and_call_original
    end

    it "configures startup and shutdown hooks" do
      configure

      expect(config).to have_received(:on).with(:startup)
      expect(config).to have_received(:on).with(:shutdown)
      expect(config.death_handlers).to have_received(:<<).with(described_class::DEATH_HANDLER)
    end
  end

  describe ".start" do
    subject(:start) { described_class.start }

    before do
      allow(SidekiqUniqueJobs::UpgradeLocks).to receive(:call).and_return(true)
    end

    it "runs upgrade and starts services" do
      start

      expect(SidekiqUniqueJobs::UpgradeLocks).to have_received(:call)
    end
  end

  describe ".reap" do
    let(:old_score) { (Time.now.to_f - 60).to_s }

    it "cleans stale digests with no LOCKED hash" do
      redis { |conn| conn.call("ZADD", "uniquejobs:digests", old_score, "uniquejobs:stale") }

      expect { described_class.reap }.to change {
        SidekiqUniqueJobs::Digests.new.count
      }.by(-1)
    end

    it "cleans orphaned locks where LOCKED hash exists but JID is not in any Sidekiq set" do
      digest = "uniquejobs:#{SecureRandom.hex(12)}"
      locked = "#{digest}:LOCKED"

      redis do |conn|
        conn.call("ZADD", "uniquejobs:digests", old_score, digest)
        conn.call("HSET", locked, SecureRandom.hex(12), '{"type":"until_executed"}')
      end

      expect { described_class.reap }.to change {
        SidekiqUniqueJobs::Digests.new.count
      }.by(-1)

      redis do |conn|
        expect(conn.call("EXISTS", locked)).to eq(0)
      end
    end

    it "preserves locks for jobs still in a queue" do
      digest = "uniquejobs:#{SecureRandom.hex(12)}"
      locked = "#{digest}:LOCKED"
      jid = SecureRandom.hex(12)
      job = { "jid" => jid, "class" => "TestWorker", "queue" => "default", "lock_digest" => digest }.to_json

      redis do |conn|
        conn.call("ZADD", "uniquejobs:digests", old_score, digest)
        conn.call("HSET", locked, jid, '{"type":"until_executed"}')
        conn.call("SADD", "queues", "default")
        conn.call("LPUSH", "queue:default", job)
      end

      expect { described_class.reap }.not_to(change { SidekiqUniqueJobs::Digests.new.count })

      redis do |conn|
        expect(conn.call("EXISTS", locked)).to eq(1)
      end
    end

    it "preserves locks for jobs in the retry set" do
      digest = "uniquejobs:#{SecureRandom.hex(12)}"
      locked = "#{digest}:LOCKED"
      jid = SecureRandom.hex(12)
      job = { "jid" => jid, "class" => "TestWorker", "queue" => "default", "lock_digest" => digest }.to_json

      redis do |conn|
        conn.call("ZADD", "uniquejobs:digests", old_score, digest)
        conn.call("HSET", locked, jid, '{"type":"until_executed"}')
        conn.call("ZADD", "retry", Time.now.to_f.to_s, job)
      end

      expect { described_class.reap }.not_to(change { SidekiqUniqueJobs::Digests.new.count })
    end

    it "returns the count of reaped digests" do
      3.times do |i|
        redis { |conn| conn.call("ZADD", "uniquejobs:digests", old_score, "uniquejobs:stale#{i}") }
      end

      expect(described_class.reap).to eq(3)
    end
  end

  describe "DEATH_HANDLER" do
    let(:item)    { { "lock_digest" => digest } }
    let(:digest)  { "uniquejobs:abcdefab" }
    let(:digests) { SidekiqUniqueJobs::Digests.new }

    before do
      allow(digests).to receive(:delete_by_digest).and_return(true)
      allow(SidekiqUniqueJobs::Digests).to receive(:new).and_return(digests)
    end

    it "deletes digests for dead jobs" do
      described_class::DEATH_HANDLER.call(item, nil)

      expect(digests).to have_received(:delete_by_digest).with(digest)
    end
  end
end
