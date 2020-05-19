# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::LockTimeout do
  let(:lock_timeout)       { described_class.new(item) }
  let(:worker_class)       { InlineWorker }
  let(:worker_class_name)  { worker_class.to_s }
  let(:schedule_time)      { nil }
  let(:item)               { { "class" => worker_class_name } }

  describe "public api" do
    subject { lock_timeout }

    it { is_expected.to respond_to(:worker_class) }
    it { is_expected.to respond_to(:calculate) }
    it { is_expected.to respond_to(:worker_options) }
    it { is_expected.to respond_to(:default_worker_options) }
  end

  describe "#worker_class" do
    subject(:worker_class) { lock_timeout.worker_class }

    let(:worker_class_name) { "InlineWorker" }

    it { is_expected.to eq(worker_class) }
  end

  describe "#calculate" do
    subject(:calculate) { lock_timeout.calculate }

    context "with sidekiq options", :with_sidekiq_options do
      let(:sidekiq_options) { { lock_timeout: 99 } }

      context "with global config", :with_global_config do
        let(:global_config) { { lock_timeout: 66 } }

        # rubocop:disable RSpec/NestedGroups
        context "with worker options", :with_worker_options do
          let(:worker_options) { { lock_timeout: 33 } }

          it { is_expected.to eq(33) }
        end
        # rubocop:enable RSpec/NestedGroups
      end
    end
  end
end
