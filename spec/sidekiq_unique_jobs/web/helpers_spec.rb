# frozen_string_literal: true

require "sidekiq_unique_jobs/web/helpers"

RSpec.describe SidekiqUniqueJobs::Web::Helpers do
  before do
    stub_const(
      "SidekiqUniqueJobs::WebHelpers",
      Class.new do
        include Sidekiq::WebHelpers
        include SidekiqUniqueJobs::Web::Helpers

        def params
          {}
        end
      end,
    )
  end

  let(:helper) { SidekiqUniqueJobs::WebHelpers.new }

  describe "#safe_relative_time" do
    subject(:safe_relative_time) { helper.safe_relative_time(time) }

    let(:frozen_time) { Time.new(1982, 6, 8, 14, 15, 34) }
    let(:time)        { Time.now.to_f }
    let(:stamp)       { Time.now.getutc.iso8601 }

    around do |example|
      Timecop.freeze(frozen_time, &example)
    end

    it "returns relative time html" do
      expect(safe_relative_time).to eq(<<~HTML.chop)
        <time class="ltr" dir="ltr" title="#{stamp}" datetime="#{stamp}">#{Time.now}</time>
      HTML
    end
  end

  describe "#cparams" do
    subject(:cparams) { helper.cparams(options) }

    before do
      allow(helper).to receive(:params).and_return({})
    end

    let(:options) do
      {
        "cursor" => "0",
        "prev_cursor" => "1",
        "bogus" => "hokuspokus",
      }
    end

    it { is_expected.to eq("cursor=0&prev_cursor=1") }
  end

  describe "#display_lock_args" do
    subject(:display_lock_args) { helper.display_lock_args(args, num) }

    let(:args) { ["abc", 1, "cde"] }
    let(:num)  { 2000 }

    it { is_expected.to eq("&quot;abc&quot;, 1, &quot;cde&quot;") }

    context "when args is nil" do
      let(:args) { nil }

      it { is_expected.to eq("Invalid job payload, args is nil") }
    end

    context "when args is not an array" do
      let(:args) { 123 }

      it { is_expected.to eq("Invalid job payload, args must be an Array, not #{args.class.name}") }
    end
  end

  describe "#unique_filename" do
    subject(:unique_filename) { helper.unique_filename(name) }

    context "when name is changelogs" do
      let(:name) { :changelogs }

      it { is_expected.to end_with("#{name}.erb") }
    end

    context "when name is _paging" do
      let(:name) { :_paging }

      it { is_expected.to end_with("#{name}.erb") }
    end

    context "when name is lock" do
      let(:name) { :lock }

      it { is_expected.to end_with("#{name}.erb") }
    end

    context "when name is locks" do
      let(:name) { :locks }

      it { is_expected.to end_with("#{name}.erb") }
    end
  end

  describe "#parse_time" do
    subject(:parse_time) { helper.parse_time(time) }

    let(:frozen_time) { Time.new(1982, 6, 8, 14, 15, 34) }

    around do |example|
      Timecop.freeze(frozen_time, &example)
    end

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
