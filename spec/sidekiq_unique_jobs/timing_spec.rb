# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Timing do
  let(:locked_time) { Time.new(2017, 8, 28, 3, 30) }

  before do
    Timecop.travel(locked_time)
  end

  describe ".current_time" do
    subject(:current_time) { described_class.current_time }

    context "when defined Process::CLOCK_MONOTONIC" do
      it { is_expected.to be_a(Float) }
    end

    context "when undefined Process::CLOCK_MONOTONIC" do
      before { hide_const("Process::CLOCK_MONOTONIC") }

      it { is_expected.to be_a(Float) }
    end
  end
end
