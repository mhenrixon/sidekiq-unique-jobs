# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::VersionCheck do
  let(:version_check) { described_class.new(version, constraint) }

  describe "#satisfied?" do
    subject(:satisfied?) { version_check.satisfied? }

    let(:version)    { "4.0.1" }
    let(:constraint) { ">= 4.0.0" }

    context "when given one constraint" do
      it { is_expected.to eq(true) }
    end

    context "when given dual constraints" do
      let(:constraint) { ">= 3.2.5 <= 4.2.1" }

      it { is_expected.to eq(true) }
    end

    context "when not satisfied" do
      let(:constraint) { ">= 5.0.0" }

      it { is_expected.to eq(false) }
    end
  end
end
