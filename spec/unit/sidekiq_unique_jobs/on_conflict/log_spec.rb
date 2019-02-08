# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs::OnConflict::Log do
  let(:strategy)      { described_class.new(item) }
  let(:unique_digest) { "uniquejobs:random-digest-value" }
  let(:jid)           { "arandomjid" }
  let(:item) do
    { "unique_digest" => unique_digest, "jid" => jid }
  end

  describe "#call" do
    it do
      allow(strategy).to receive(:log_info)
      strategy.call
      expect(strategy).to have_received(:log_info).with(
        "skipping job with id (#{jid}) because unique_digest: (#{unique_digest}) already exists",
      )
    end
  end

  describe "#replace?" do
    subject { strategy.replace? }

    it { is_expected.to eq(false) }
  end
end
