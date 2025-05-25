# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::LockTTL do
  let(:item)            { { "class" => job_class_name, "at" => schedule_time } }
  let(:calculator)      { described_class.new(item) }
  let(:job_class_name)  { "MyUniqueJob" }
  let(:schedule_time)   { nil }
  let(:job_options) do
    { lock: :until_executed, lock_ttl: 7_200, queue: :customqueue, retry: 10 }
  end

  before do
    allow(MyUniqueJob).to receive(:get_sidekiq_options).and_return(job_options)
  end

  describe "public api" do
    subject { calculator }

    it { is_expected.to respond_to(:time_until_scheduled) }
    it { is_expected.to respond_to(:job_class) }
    it { is_expected.to respond_to(:calculate) }
    it { is_expected.to respond_to(:job_options) }
    it { is_expected.to respond_to(:default_job_options) }
  end

  describe "#time_until_scheduled" do
    subject(:time_until_scheduled) { calculator.time_until_scheduled }

    context "when not scheduled" do
      it { is_expected.to eq(0) }
    end

    context "when scheduled" do
      let(:schedule_time) { Time.now.utc.to_i + (24 * 60 * 60) }
      let(:now_in_utc)    { Time.now.utc.to_i }

      it do
        Timecop.travel(Time.at(now_in_utc)) do
          expect(time_until_scheduled).to be_within(10).of(schedule_time - now_in_utc)
        end
      end
    end
  end

  describe "#calculate" do
    subject(:calculate) { calculator.calculate }

    context "when no lock_ttl is set" do
      let(:item) { { "class" => job_class_name, "lock_ttl" => nil } }
      let(:job_options) { { lock: "until_expired", "lock_ttl" => nil } }

      it "returns the default lock_ttl" do
        expect(calculate).to eq(SidekiqUniqueJobs.config.lock_ttl)
      end

      it "returns nil" do
        SidekiqUniqueJobs.config.lock_ttl = nil
        expect(calculate).to be_nil
      end
    end

    context "when item lock_ttl is numeric" do
      let(:item) { { "class" => job_class_name, "lock_ttl" => 10 } }

      it do
        expect(calculate).to eq(10)
      end
    end

    context "when item lock_ttl is a string" do
      let(:item) { { "class" => job_class_name, "lock_ttl" => "10" } }

      it do
        expect(calculate).to eq(10)
      end
    end

    context "when item lock_ttl is a proc" do
      let(:item) { { "class" => job_class_name, "lock_ttl" => ->(_args) { 20 } } }

      it do
        expect(calculate).to eq(20)
      end
    end

    context "when item lock_ttl is a function symbol" do
      let(:job_class_name) { "MyOtherUniqueJob" }
      let(:item)           { { "class" => job_class_name, "lock_ttl" => :ttl_fn } }

      it do
        stub_const(
          job_class_name,
          Class.new do
            def self.ttl_fn(_args)
              99
            end
          end,
        )

        expect(calculate).to eq(99)
      end
    end
  end

  describe "#job_class" do
    subject(:job_class) { calculator.job_class }

    let(:job_class_name) { "MyUniqueJob" }

    it { is_expected.to eq(MyUniqueJob) }
  end
end
