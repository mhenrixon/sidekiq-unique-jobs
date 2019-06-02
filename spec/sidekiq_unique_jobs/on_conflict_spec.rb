# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs::OnConflict do
  it { expect(described_class.strategies).to eq(SidekiqUniqueJobs.strategies) }

  describe "#find_strategy" do
    before do
      allow(SidekiqUniqueJobs).to receive(:strategies).and_return(
        log: SidekiqUniqueJobs::OnConflict::Log,
      )
    end

    context "when a strategy is found" do
      it "returns the given strategy" do
        expect(described_class.find_strategy("log")).to eq(SidekiqUniqueJobs::OnConflict::Log)
      end
    end

    context "when a strategy is not found" do
      it "does not raise any exception" do
        expect { described_class.find_strategy(:foo) }.not_to raise_exception
      end

      it "returns an OnConflict::NullStrategy" do
        expect(described_class.find_strategy(:foo)).to eq(SidekiqUniqueJobs::OnConflict::NullStrategy)
      end
    end
  end
end
