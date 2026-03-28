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
    it "cleans stale digests" do
      # Create a stale entry (no LOCKED hash)
      redis { |conn| conn.call("ZADD", "uniquejobs:digests", Time.now.to_f.to_s, "uniquejobs:stale") }

      expect { described_class.reap }.to change {
        SidekiqUniqueJobs::Digests.new.count
      }.by(-1)
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
