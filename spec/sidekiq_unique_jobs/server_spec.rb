# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Server do
  describe ".configure" do
    subject(:configure) { described_class.configure(config) }

    let(:config) { Sidekiq }

    before do
      allow(config).to receive(:on).with(:startup).and_call_original
      allow(config).to receive(:on).with(:shutdown).and_call_original
      allow(config.death_handlers).to receive(:<<).and_call_original
    end

    it "configures startup" do
      configure

      expect(config).to have_received(:on).with(:startup)
      expect(config).to have_received(:on).with(:shutdown)

      expect(config.death_handlers).to have_received(:<<)
        .with(described_class.death_handler)
    end
  end

  describe ".start" do
    subject(:start) { described_class.start }

    before do
      allow(SidekiqUniqueJobs::UpdateVersion).to receive(:call).and_return(true)
      allow(SidekiqUniqueJobs::UpgradeLocks).to receive(:call).and_return(true)
      allow(SidekiqUniqueJobs::Orphans::Manager).to receive(:start).and_return(true)
    end

    it "starts processes in the background" do
      start

      expect(SidekiqUniqueJobs::UpdateVersion).to have_received(:call)
      expect(SidekiqUniqueJobs::UpgradeLocks).to have_received(:call)
      expect(SidekiqUniqueJobs::Orphans::Manager).to have_received(:start)
    end
  end

  describe ".stop" do
    subject(:stop) { described_class.stop }

    before do
      allow(SidekiqUniqueJobs::Orphans::Manager).to receive(:stop).and_return(true)
    end

    it "starts processes in the background" do
      stop

      expect(SidekiqUniqueJobs::Orphans::Manager).to have_received(:stop)
    end
  end

  describe ".death_handler" do
    subject(:death_handler) { described_class.death_handler }

    let(:item)    { { "lock_digest" => digest } }
    let(:digest)  { "uniquejobs:abcdefab" }
    let(:digests) { SidekiqUniqueJobs::Digests.new }

    before do
      allow(digests).to receive(:delete_by_digest).and_return(true)
      allow(SidekiqUniqueJobs::Digests).to receive(:new).and_return(digests)
    end

    it "deletes digests for dead jobs" do
      death_handler.call(item, nil)

      expect(digests).to have_received(:delete_by_digest).with(digest)
    end
  end
end
