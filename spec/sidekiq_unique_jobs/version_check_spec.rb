# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::VersionCheck do
  describe ".satisfied?" do
    subject(:satisfied?) { described_class.satisfied?(version, constraint) }

    let(:version)       { "4.0.1" }
    let(:constraint)    { ">= 4.0.0" }

    context "when given one constraint" do
      it { is_expected.to be(true) }
    end

    context "when given dual constraints" do
      let(:constraint) { ">= 3.2.5 <= 4.2.1" }

      it { is_expected.to be(true) }
    end

    context "when not satisfied" do
      let(:constraint) { ">= 5.0.0" }

      it { is_expected.to be(false) }
    end
  end

  describe ".unfulfilled?" do
    subject(:unfulfilled?) { described_class.unfulfilled?(version, constraint) }

    let(:version)    { "4.0.1" }
    let(:constraint) { ">= 4.0.0" }

    context "when given one constraint" do
      it { is_expected.to be(false) }
    end

    context "when given dual constraints" do
      let(:constraint) { ">= 3.2.5 <= 4.2.1" }

      it { is_expected.to be(false) }
    end

    context "when not satisfied" do
      let(:constraint) { ">= 5.0.0" }

      it { is_expected.to be(true) }
    end
  end

  describe "#satisfied?" do
    subject(:satisfied?) { version_check.satisfied? }

    let(:version_check) { described_class.new(version, constraint) }
    let(:version)       { "4.0.1" }
    let(:constraint)    { ">= 4.0.0" }

    context "when given one constraint" do
      it { is_expected.to be(true) }
    end

    context "when given dual constraints" do
      let(:constraint) { ">= 3.2.5 <= 4.2.1" }

      it { is_expected.to be(true) }
    end

    context "when not satisfied" do
      let(:constraint) { ">= 5.0.0" }

      it { is_expected.to be(false) }
    end
  end
end
