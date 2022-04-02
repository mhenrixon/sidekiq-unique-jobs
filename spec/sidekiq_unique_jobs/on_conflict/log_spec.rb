# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::OnConflict::Log do
  let(:strategy)    { described_class.new(item) }
  let(:lock_digest) { "uniquejobs:random-digest-value" }
  let(:jid)         { "arandomjid" }
  let(:item) do
    { "lock_digest" => lock_digest, "jid" => jid }
  end

  describe "#call" do
    it do
      allow(strategy).to receive(:log_info)
      strategy.call
      expect(strategy).to have_received(:log_info).with(
        "Skipping job with id (#{jid}) because lock_digest: (#{lock_digest}) already exists",
      )
    end
  end

  describe "#replace?" do
    subject { strategy.replace? }

    it { is_expected.to be(false) }
  end
end
