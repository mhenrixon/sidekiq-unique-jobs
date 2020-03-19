# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::UniqueArgs do
  let(:unique_args)  { described_class.new(item) }
  let(:worker_class) { UntilExecutedJob }
  let(:class_name)   { worker_class.to_s }
  let(:queue)        { "myqueue" }
  let(:args)         { [[1, 2]] }
  let(:item) do
    {
      "class" => class_name,
      "queue" => queue,
      "args" => args,
    }
  end

  describe "#unique_args_enabled?" do
    subject(:unique_args_enabled?) { unique_args.unique_args_enabled? }

    with_default_worker_options(unique: :until_executed, unique_args: ->(args) { args[1]["test"] }) do
      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args) do
        it { is_expected.to eq(:unique_args) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: false) do
        it { is_expected.to be_a(Proc) }
      end
    end

    with_default_worker_options(unique: false, unique_args: nil) do
      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args) do
        it { is_expected.to eq(:unique_args) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: false) do
        it { is_expected.to be_falsy }
      end

      with_sidekiq_options_for("MissingWorker", unique_args: true) do
        it { is_expected.to be_falsy }
      end

      it { is_expected.to be_falsy }
    end
  end

  describe "#filtered_args" do
    subject(:filtered_args) { unique_args.filtered_args }

    let(:args) { [1, "test" => "it"] }

    context "when #unique_args_method is nil" do
      before do
        allow(unique_args).to receive(:unique_args_method).and_return(nil)
      end

      it { is_expected.to eq(args) }
    end
  end

  describe "#filter_by_proc" do
    subject(:filter_by_proc) { unique_args.filter_by_proc(args) }

    let(:args) { [1, "test" => "it"] }

    context "when #unique_args_method is a proc" do
      let(:filter) { ->(args) { args[1]["test"] } }

      before { allow(unique_args).to receive(:unique_args_method).and_return(filter) }

      it { is_expected.to eq("it") }
    end

    with_default_worker_options(unique_args: ->(args) { args.first }) do
      it { is_expected.to eq(1) }
    end
  end

  describe "#filter_by_symbol" do
    subject(:filter_by_symbol) { unique_args.filter_by_symbol(args) }

    context "when filter is a working symbol" do
      let(:worker_class)  { UniqueJobWithFilterMethod }
      let(:args)          { ["name", 2, "whatever" => nil, "type" => "test"] }
      let(:filtered_args) { %w[name test] }

      it { is_expected.to eq(filtered_args) }
    end

    context "when worker takes conditional parameters" do
      let(:worker_class) { UniqueJobWithoutUniqueArgsParameter }
      let(:args)         { [1] }

      it "raises a descriptive error" do
        expect { filter_by_symbol }
          .to raise_error(
            SidekiqUniqueJobs::InvalidUniqueArguments,
            "UniqueJobWithoutUniqueArgsParameter#unique_args takes 0 arguments," \
            " received [1]",
          )
      end

      context "when provided nil" do
        let(:args) { [] }

        it "raises a descriptive error" do
          expect { filter_by_symbol }
            .to raise_error(
              SidekiqUniqueJobs::InvalidUniqueArguments,
              "UniqueJobWithoutUniqueArgsParameter#unique_args takes 0 arguments," \
              " received []",
            )
        end
      end
    end

    context "when workers unique_args method doesn't take parameters" do
      let(:worker_class) { UniqueJobWithoutUniqueArgsParameter }
      let(:args)         { ["name", 2, "whatever" => nil, "type" => "test"] }

      it "raises a descriptive error" do
        expect { filter_by_symbol }
          .to raise_error(
            SidekiqUniqueJobs::InvalidUniqueArguments,
            'UniqueJobWithoutUniqueArgsParameter#unique_args takes 0 arguments,' \
            ' received ["name", 2, {"whatever"=>nil, "type"=>"test"}]',
          )
      end
    end

    context "when @worker_class does not respond_to unique_args_method" do
      let(:worker_class) { UniqueJobWithNoUniqueArgsMethod }
      let(:args)         { ["name", 2, "whatever" => nil, "type" => "test"] }

      it { is_expected.to eq(args) }
    end

    context "when workers unique_args method returns nil" do
      let(:worker_class) { UniqueJobWithNilUniqueArgs }
      let(:args) { ["name", 2, "whatever" => nil, "type" => "test"] }

      it { is_expected.to eq(nil) }
    end
  end
end
