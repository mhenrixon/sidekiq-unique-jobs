# frozen_string_literal: true

require "spec_helper"
require "sidekiq_unique_jobs/web/helpers"

RSpec.describe SidekiqUniqueJobs::Web::Helpers do
  describe "#safe_relative_time" do
    subject(:safe_relative_time) { described_class.safe_relative_time(time) }

    let(:frozen_time) { Time.new(1982, 6, 8, 14, 15, 34) }
    let(:time)        { Time.now.to_f }

    before { Timecop.freeze(frozen_time) }

    after { Timecop.return }

    it "returns relative time html" do
      expect(safe_relative_time).to eq(<<~HTML.chop)
        <time class="ltr" dir="ltr" title="1982-06-08T12:15:34Z" datetime="1982-06-08T12:15:34Z">#{Time.now}</time>
      HTML
    end
  end

  describe "#parse_time" do
    subject(:parse_time) { described_class.parse_time(time) }

    let(:frozen_time) { Time.new(1982, 6, 8, 14, 15, 34) }

    before { Timecop.freeze(frozen_time) }

    after { Timecop.return }

    context "when time is an Integer" do
      let(:time) { Time.now.to_i }

      it { is_expected.to eq(Time.now) }
    end

    context "when time is an Float" do
      let(:time) { Time.now.to_f }

      it { is_expected.to eq(Time.now) }
    end

    context "when time is a Time" do
      let(:time) { Time.now }

      it { is_expected.to eq(Time.now) }
    end

    context "when time is a String" do
      let(:time) { Time.now.to_s }

      it { is_expected.to eq(Time.now) }
    end
  end
end
