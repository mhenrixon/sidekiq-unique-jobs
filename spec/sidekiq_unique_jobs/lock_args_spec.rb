# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::LockArgs do
  let(:lock_args)  { described_class.new(item) }
  let(:job_class)  { UntilExecutedJob }
  let(:class_name) { job_class.to_s }
  let(:queue)      { "myqueue" }
  let(:args)       { [[1, 2]] }
  let(:item) do
    {
      "class" => class_name,
      "queue" => queue,
      "args" => args,
    }
  end

  describe "#lock_args_enabled?" do
    subject(:lock_args_enabled?) { lock_args.lock_args_enabled? }

    context "with default job options", :with_sidekiq_options do
      let(:sidekiq_options) { { unique: :until_executed, lock_args_method: ->(args) { args[1] } } }

      context "when `lock_args_method: :lock_args` in worker", :with_job_options do
        let(:job_options) { { lock_args_method: :lock_args } }

        it { is_expected.to eq(:lock_args) }
      end

      context "when `lock_args_method: false` in worker", :with_job_options do
        let(:job_options) { { lock_args_method: false } }

        it { is_expected.to be_a(Proc) }
      end
    end

    context "when disabled in default_worker_options", :with_sidekiq_options do
      let(:sidekiq_options) { { unique: false, lock_args_method: nil } }

      context "when `lock_args_method: :lock_args` in worker", :with_job_options do
        let(:job_options) { { lock_args_method: :lock_args } }

        it { is_expected.to eq(:lock_args) }
      end

      context "when `lock_args_method: false` in worker", :with_job_options do
        let(:job_options) { { lock_args_method: false } }

        it { is_expected.to be_nil }
      end
    end
  end

  describe "#filtered_args" do
    subject(:filtered_args) { lock_args.filtered_args }

    let(:args) { [1, { "test" => "it" }] }

    context "when #lock_args_method is nil" do
      before do
        allow(lock_args).to receive(:lock_args_method).and_return(nil)
      end

      it { is_expected.to eq(args) }
    end
  end

  describe "#filter_by_proc" do
    subject(:filter_by_proc) { lock_args.filter_by_proc(args) }

    context "when #lock_args_method is a proc" do
      let(:args)   { [1, 2] }
      let(:filter) { ->(args) { args[1] } }

      before { allow(lock_args).to receive(:lock_args_method).and_return(filter) }

      it { is_expected.to eq(2) }
    end

    context "when configured globally" do
      let(:args)   { %w[abc cde] }
      let(:filter) { ->(args) { args[1] } }

      it "uses global filter" do
        Sidekiq.use_options(lock_args_method: filter) do
          expect(filter_by_proc).to eq("cde")
        end
      end
    end
  end

  describe "#filter_by_symbol" do
    subject(:filter_by_symbol) { lock_args.filter_by_symbol(args) }

    context "when filter is a working symbol" do
      let(:job_class)     { UniqueJobWithFilterMethod }
      let(:args)          { ["name", 2, { "whatever" => nil, "type" => "test" }] }
      let(:filtered_args) { %w[name test] }

      it { is_expected.to eq(filtered_args) }
    end

    context "when worker takes conditional parameters" do
      let(:job_class) { UniqueJobWithoutUniqueArgsParameter }
      let(:args)      { [1] }

      it "raises a descriptive error" do
        expect { filter_by_symbol }
          .to raise_error(
            SidekiqUniqueJobs::InvalidUniqueArguments,
            a_string_starting_with(
              "UniqueJobWithoutUniqueArgsParameter#unique_args takes 0 arguments, " \
              "received [1]",
            ),
          )
      end

      context "when provided nil" do
        let(:args) { [] }

        it "raises a descriptive error" do
          expect { filter_by_symbol }
            .to raise_error(
              SidekiqUniqueJobs::InvalidUniqueArguments,
              a_string_starting_with(
                "UniqueJobWithoutUniqueArgsParameter#unique_args takes 0 arguments, " \
                "received []",
              ),
            )
        end
      end
    end

    context "when workers lock_args method doesn't take parameters" do
      let(:job_class) { UniqueJobWithoutUniqueArgsParameter }
      let(:args)      { ["name", 2, { "whatever" => nil, "type" => "test" }] }

      it "raises a descriptive error" do
        expect { filter_by_symbol }
          .to raise_error(
            SidekiqUniqueJobs::InvalidUniqueArguments,
            a_string_starting_with(
              'UniqueJobWithoutUniqueArgsParameter#unique_args takes 0 arguments, ' \
              'received ["name", 2, {"whatever"=>nil, "type"=>"test"}]',
            ),
          )
      end
    end

    context "when @job_class does not respond_to lock_args_method" do
      let(:job_class) { UniqueJobWithNoUniqueArgsMethod }
      let(:args)      { ["name", 2, { "whatever" => nil, "type" => "test" }] }

      it { is_expected.to eq(args) }
    end

    context "when workers lock_args method returns nil" do
      let(:job_class) { UniqueJobWithNilUniqueArgs }
      let(:args)      { ["name", 2, { "whatever" => nil, "type" => "test" }] }

      it { is_expected.to be_nil }
    end
  end
end
