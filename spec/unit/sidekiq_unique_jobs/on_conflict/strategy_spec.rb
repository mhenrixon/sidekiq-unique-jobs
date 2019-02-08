# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs::OnConflict::Strategy, redis: :redis do
  let(:strategy)      { described_class.new(item) }
  let(:unique_digest) { "uniquejobs:56c68cab5038eb57959538866377560d" }
  let(:item) do
    { "unique_digest" => unique_digest, "queue" => :customqueue }
  end

  describe "#replace?" do
    subject { strategy.replace? }

    it { is_expected.to eq(false) }
  end

  describe "#call" do
    let(:call) { strategy.call }

    it "raises an error" do
      expect { call }.to raise_error(NotImplementedError, "needs to be implemented in child class")
    end
  end

  describe "#replace?" do
    subject { strategy.replace? }

    it { is_expected.to eq(false) }
  end
end
