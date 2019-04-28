require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Timing do
  let(:locked_time) { Time.new(2017, 08, 28, 3, 30) }

  before do
    Timecop.travel(locked_time)
  end

  describe "#current_time" do
    it { is_expected.to eq(locked_time) }
  end
end

