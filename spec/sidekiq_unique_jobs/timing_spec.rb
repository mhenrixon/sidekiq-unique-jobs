# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Timing do
  let(:locked_time) { Time.new(2017, 8, 28, 3, 30) }

  before do
    Timecop.travel(locked_time)
  end

  after do
    Timecop.return
  end

  describe ".time_source" do
    subject(:time_source) { described_class.time_source.call }

    context "when defined Process::CLOCK_MONOTONIC" do
      it { is_expected.to be_a(Integer) }
    end

    context "when undefined Process::CLOCK_MONOTONIC" do
      before { hide_const("Process::CLOCK_MONOTONIC") }

      it { is_expected.to be_a(Integer) }
    end
  end
end
