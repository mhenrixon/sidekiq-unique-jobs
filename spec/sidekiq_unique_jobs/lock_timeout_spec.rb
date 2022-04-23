# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::LockTimeout do
  let(:lock_timeout)   { described_class.new(item) }
  let(:job_class)      { InlineWorker }
  let(:job_class_name) { job_class.to_s }
  let(:schedule_time)  { nil }
  let(:item)           { { "class" => job_class_name } }

  describe "public api" do
    subject { lock_timeout }

    it { is_expected.to respond_to(:job_class) }
    it { is_expected.to respond_to(:calculate) }
    it { is_expected.to respond_to(:job_options) }
    it { is_expected.to respond_to(:default_job_options) }
  end

  describe "#job_class" do
    subject(:job_class) { lock_timeout.job_class }

    let(:job_class_name) { "InlineWorker" }

    it { is_expected.to eq(job_class) }
  end

  describe "#calculate" do
    subject(:calculate) { lock_timeout.calculate }

    context "with sidekiq options", :with_sidekiq_options do
      let(:sidekiq_options) { { lock_timeout: 99 } }

      context "with global config", :with_global_config do
        let(:global_config) { { lock_timeout: 66 } }

        context "with worker options", :with_job_options do
          let(:job_options) { { lock_timeout: 33 } }

          it { is_expected.to eq(33) }
        end
      end
    end
  end
end
