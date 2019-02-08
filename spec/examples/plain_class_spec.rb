# frozen_string_literal: true

require "spec_helper"
RSpec.describe PlainClass do
  describe ".run" do
    subject { described_class.run(arg) }

    let(:arg) { "argument" }

    it { is_expected.to eq(["argument"]) }
  end

  describe "#run" do
    subject { described_class.new.run(arg) }

    let(:arg) { "another argument" }

    it { is_expected.to eq(["another argument"]) }
  end
end
