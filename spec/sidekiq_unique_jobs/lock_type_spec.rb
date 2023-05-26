# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::LockType do
  let(:lock_calculator) { described_class.new("class" => job_class_name, "lock" => lock) }
  let(:job_class_name)  { "MyUniqueJob" }
  let(:lock)            { :until_expired }

  describe "public api" do
    subject { lock_calculator }

    it { is_expected.to respond_to(:job_class) }
    it { is_expected.to respond_to(:job_options) }
    it { is_expected.to respond_to(:default_job_options) }
  end

  describe "#call" do
    subject(:calculated_lock) { lock_calculator.call }

    it { is_expected.to eq(lock) }

    context "when item's lock is nil" do
      let(:lock) { nil }

      it "is expected to equal the job class' lock option" do
        expect(MyUniqueJob.sidekiq_options["lock"]).to eq(:until_executed)
        expect(calculated_lock).to eq(:until_executed)
      end

      context "when job class sidekiq options lock is nil" do
        it "uses the Sidekiq default job options" do
          allow(MyUniqueJob).to receive(:get_sidekiq_options).and_return({})
          allow(lock_calculator).to receive(:default_job_options).and_return({ "lock" => :until_executing })
          expect(calculated_lock).to eq(:until_executing)
        end
      end
    end
  end

  describe "#job_class" do
    subject(:job_class) { lock_calculator.job_class }

    let(:job_class_name) { "MyUniqueJob" }

    it { is_expected.to eq(MyUniqueJob) }
  end
end
