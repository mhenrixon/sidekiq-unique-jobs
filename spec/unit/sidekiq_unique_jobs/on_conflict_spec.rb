# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::OnConflict do
  describe "::STRAGEGIES" do
    subject { described_class::STRATEGIES }

    let(:expected) do
      {
        log: described_class::Log,
        raise: described_class::Raise,
        reject: described_class::Reject,
        replace: described_class::Replace,
        reschedule: described_class::Reschedule,
      }
    end

    it { is_expected.to eq(expected) }
  end
end
