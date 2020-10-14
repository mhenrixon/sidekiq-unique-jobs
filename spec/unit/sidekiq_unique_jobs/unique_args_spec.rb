# frozen_string_literal: true

require "spec_helper"
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

  describe "#unique_digest" do
    subject(:unique_digest) { unique_args.unique_digest }

    context "when args are empty" do
      let(:another_unique_args) { described_class.new(item) }
      let(:worker_class)        { WithoutArgumentJob }
      let(:args)                { [] }

      context "with the same unique args" do
        it "equals to unique_digest for that item" do
          expect(unique_digest).to eq(another_unique_args.unique_digest)
        end
      end
    end

    shared_examples "unique digest" do
      context "with another item" do
        let(:another_unique_args) { described_class.new(another_item) }

        context "with the same unique args" do
          let(:another_item) { item.merge("args" => [1, 2, "type" => "it"]) }

          it "equals to unique_digest for that item" do
            expect(unique_digest).to eq(another_unique_args.unique_digest)
          end
        end

        context "with different unique args" do
          let(:another_item) { item.merge("args" => [1, 3, "type" => "that"]) }

          it "differs from unique_digest for that item" do
            expect(unique_digest).not_to eq(another_unique_args.unique_digest)
          end
        end
      end
    end

    context "when unique_args is a proc" do
      let(:worker_class) { MyUniqueJobWithFilterProc }
      let(:args)         { [1, 2, "type" => "it"] }

      it_behaves_like "unique digest"
    end

    context "when unique_args is a symbol" do
      let(:worker_class) { MyUniqueJobWithFilterMethod }
      let(:args)         { [1, 2, "type" => "it"] }

      it_behaves_like "unique digest"
    end
  end

  describe "#digestable_hash" do
    subject(:digestable_hash) { unique_args.digestable_hash }

    let(:expected_hash) do
      { "class" => "UntilExecutedJob", "queue" => "myqueue", "unique_args" => [[1, 2]] }
    end

    shared_examples "a digestable hash" do
      it { is_expected.to eq(expected_hash) }
    end

    it_behaves_like "a digestable hash"

    with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_on_all_queues: true) do
      let(:expected_hash) { { "class" => "UntilExecutedJob", "unique_args" => [[1, 2]] } }

      it_behaves_like "a digestable hash"
    end

    with_sidekiq_options_for(UntilExecutedJob, unique_across_workers: true) do
      let(:expected_hash) { { "queue" => "myqueue", "unique_args" => [[1, 2]] } }

      it_behaves_like "a digestable hash"
    end
  end

  describe "#unique_args_enabled?" do
    subject(:unique_args_enabled?) { unique_args.unique_args_enabled? }

    with_default_worker_options(unique: :until_executed, unique_args: ->(args, _item) { args[1]["test"] }) do
      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args) do
        it { is_expected.to eq(:unique_args) } # rubocop:disable RSpec/RepeatedExample
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: false) do
        specify do
          expect { unique_args_enabled? }.to raise_error(NoMethodError, "undefined method `[]' for nil:NilClass")
        end
      end
    end

    with_default_worker_options(unique: false, unique_args: nil) do
      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args) do
        it { is_expected.to eq(:unique_args) } # rubocop:disable RSpec/RepeatedExample
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: false) do
        it { is_expected.to be_falsy } # rubocop:disable RSpec/RepeatedExample
      end

      with_sidekiq_options_for("MissingWorker", unique_args: true) do
        it { is_expected.to be_falsy } # rubocop:disable RSpec/RepeatedExample
      end

      it { is_expected.to be_falsy } # rubocop:disable RSpec/RepeatedExample
    end
  end

  describe "#unique_across_queues?" do
    subject(:unique_across_queues?) { unique_args.unique_across_queues? }

    let(:worker_class) { UntilExecutedJob }

    it { is_expected.to eq(nil) }

    with_sidekiq_options_for(UntilExecutedJob, unique_on_all_queues: true) do
      it { is_expected.to eq(true) }
    end

    with_sidekiq_options_for(UntilExecutedJob, unique_on_all_queues: false) do
      it { is_expected.to eq(false) }
    end
  end

  describe "#unique_across_workers?" do
    subject(:unique_across_workers?) { unique_args.unique_across_workers? }

    it { is_expected.to eq(nil) }

    with_sidekiq_options_for(UntilExecutedJob, unique_across_workers: true) do
      it { is_expected.to eq(true) }
    end

    with_sidekiq_options_for(UntilExecutedJob, unique_across_workers: false) do
      it { is_expected.to eq(false) }
    end
  end

  describe "#filtered_args" do
    subject(:filtered_args) { unique_args.filtered_args(args) }

    let(:args) { [1, "test" => "it"] }

    before do
      allow(unique_args).to receive(:unique_args_method).and_return(unique_args_method)
    end

    context "when #unique_args_method is nil" do
      let(:unique_args_method) { nil }

      it "logs a debug message" do
        allow(unique_args).to receive(:log_debug)
        filtered_args

        expect(unique_args)
          .to have_received(:log_debug)
          .with("filtered_args arguments not filtered (using all arguments for uniqueness)")
      end

      it { is_expected.to eq(args) }
    end
  end

  describe "#filter_by_proc" do
    subject(:filter_by_proc) { unique_args.filter_by_proc(args) }

    let(:args) { [1, "test" => "it"] }

    context "when #unique_args_method is a proc" do
      let(:filter) { ->(args, _item) { args[1]["test"] } }

      before { allow(unique_args).to receive(:unique_args_method).and_return(filter) }

      it { is_expected.to eq("it") }
    end

    with_default_worker_options(unique_args: ->(args, _item) { args.first }) do
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

      it { is_expected.to eq([1]) }

      context "when provided nil" do
        let(:args) { [] }

        it { is_expected.to eq([]) }
      end
    end

    context "when workers unique_args method doesn't take parameters" do
      let(:worker_class) { UniqueJobWithoutUniqueArgsParameter }
      let(:args)         { ["name", 2, "whatever" => nil, "type" => "test"] }

      it { is_expected.to eq(args) }
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
