# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::UniqueArgs do
  let(:item) { { 'class' => 'UntilExecutedJob', 'queue' => 'myqueue', 'args' => [[1, 2]] } }
  let(:unique_args) { described_class.new(item) }

  describe '#unique_digest' do
    subject { unique_args.unique_digest }

    context 'when args are empty' do
      let(:item) { { 'class' => 'WithoutArgumentJob', 'args' => [] } }
      let(:another_unique_args) { described_class.new(item) }

      context 'with the same unique args' do
        it 'equals to unique_digest for that item' do
          expect(subject).to eq(another_unique_args.unique_digest)
        end
      end
    end

    shared_examples 'unique digest' do
      context 'given another item' do
        let(:another_unique_args) { described_class.new(another_item) }

        context 'with the same unique args' do
          let(:another_item) { item.merge('args' => [1, 2, 'type' => 'it']) }

          it 'equals to unique_digest for that item' do
            expect(subject).to eq(another_unique_args.unique_digest)
          end
        end

        context 'with different unique args' do
          let(:another_item) { item.merge('args' => [1, 3, 'type' => 'that']) }
          it 'differs from unique_digest for that item' do
            expect(subject).not_to eq(another_unique_args.unique_digest)
          end
        end
      end
    end

    context 'when unique_args is a proc' do
      let(:item) do
        {
          'class' => 'MyUniqueJobWithFilterProc',
          'queue' => 'customqueue',
          'args' => [1, 2, 'type' => 'it'],
        }
      end

      it_behaves_like 'unique digest'
    end

    context 'when unique_args is a symbol' do
      let(:item) do
        {
          'class' => 'MyUniqueJobWithFilterMethod',
          'queue' => 'customqueue',
          'args' => [1, 2, 'type' => 'it'],
        }
      end

      it_behaves_like 'unique digest'
    end
  end

  describe '#digestable_hash' do
    subject { unique_args.digestable_hash }

    let(:expected_hash) do
      { 'class' => 'UntilExecutedJob', 'queue' => 'myqueue', 'unique_args' => [[1, 2]] }
    end

    it { is_expected.to eq(expected_hash) }

    with_global_config(unique_args_enabled: true) do
      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_on_all_queues: true) do
        let(:expected_hash) { { 'class' => 'UntilExecutedJob', 'unique_args' => [[1, 2]] } }
        it { is_expected.to eq(expected_hash) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_across_workers: true) do
        let(:expected_hash) { { 'queue' => 'myqueue', 'unique_args' => [[1, 2]] } }

        it { is_expected.to eq(expected_hash) }
      end
    end
  end

  describe '#unique_args_enabled?' do
    subject { unique_args.unique_args_enabled? }

    with_default_worker_options(unique: :until_executed, unique_args: ->(args) { args[1]['test'] }) do
      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args) do
        it { is_expected.to eq(:unique_args) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: false) do
        it { is_expected.to be_a(Proc) }

        context 'when raise_unique_args_errors is true' do
          before { SidekiqUniqueJobs.config.raise_unique_args_errors = true }
          after { SidekiqUniqueJobs.config.raise_unique_args_errors = false }

          it { expect { subject }.to raise_error(NoMethodError, "undefined method `[]' for nil:NilClass") }
        end

        context 'when raise_unique_args_errors is false' do
          it { is_expected.to be_a(Proc) }
        end
      end
    end

    with_default_worker_options(unique: false, unique_args: nil) do
      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args) do
        it { is_expected.to eq(:unique_args) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: false) do
        it { is_expected.to be_falsy }
      end

      with_sidekiq_options_for('MissingWorker', unique_args: true) do
        it { is_expected.to be_falsy }
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '#unique_on_all_queues?' do
    subject { unique_args.unique_on_all_queues? }

    with_global_config(unique_args_enabled: true) do
      it { is_expected.to eq(nil) }

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_on_all_queues: true) do
        it { is_expected.to eq(true) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_on_all_queues: false) do
        it { is_expected.to be_falsy }
      end
    end

    with_global_config(unique_args_enabled: false) do
      it { is_expected.to eq(nil) }

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_on_all_queues: false) do
        it { is_expected.to eq(false) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_on_all_queues: true) do
        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#unique_across_workers?' do
    subject { unique_args.unique_across_workers? }

    with_global_config(unique_args_enabled: true) do
      it { is_expected.to eq(nil) }

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_across_workers: true) do
        it { is_expected.to eq(true) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_across_workers: false) do
        it { is_expected.to be_falsy }
      end
    end

    with_global_config(unique_args_enabled: false) do
      it { is_expected.to eq(nil) }

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_across_workers: false) do
        it { is_expected.to eq(false) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_across_workers: true) do
        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#filter_by_proc' do
    let(:filter) { ->(args) { args[1]['test'] } }
    let(:args) { [1, 'test' => 'it'] }
    let(:unique_args) { described_class.new(item) }

    subject { unique_args.filter_by_proc(args) }

    context 'without any default worker options configured' do
      before do
        allow(unique_args).to receive(:unique_args_method).and_return(filter)
      end

      it 'returns the value of theoptions hash ' do
        expect(subject).to eq('it')
      end
    end

    context 'when #unique_args_method is nil' do
      before do
        allow(unique_args).to receive(:unique_args_method).and_return(nil)
      end

      it 'returns the value of theoptions hash ' do
        expect(SidekiqUniqueJobs.logger).to receive(:warn) do |&block|
          expect(block.call).to eq('filter_by_proc : unique_args_method is nil. Returning ([1, {"test"=>"it"}])')
        end
        expect(subject).to eq(args)
      end
    end

    with_default_worker_options(unique: :until_executed, unique_args: ->(args) { args[1].dig('test') }) do
      it 'returns the value of the provided options' do
        expect(subject).to eq('it')
      end
    end
  end

  describe '#filter_by_symbol' do
    subject { unique_args.filter_by_symbol(args) }

    context 'when filter is a working symbol' do
      let(:item) do
        { 'class' => 'UniqueJobWithFilterMethod',
          'queue' => 'myqueue',
          'args' => [[1, 2]] }
      end

      let(:args) { ['name', 2, 'whatever' => nil, 'type' => 'test'] }

      it 'returns the value of the provided class method' do
        expected = %w[name test]

        expect(unique_args.logger).to receive(:debug) do |&block|
          expect(block.call).to eq("filter_by_symbol : filtered_args(#{args}) => #{expected}")
        end

        expect(subject).to eq(expected)
      end
    end

    context 'when worker takes conditional parameters' do
      let(:item) do
        { 'class' => 'UniqueJobWithoutUniqueArgsParameter',
          'queue' => 'myqueue',
          'args' => [1] }
      end
      let(:args) { [1] }

      it { is_expected.to eq(args) }

      context 'when provided nil' do
        let(:args) { [] }

        it { is_expected.to eq(args) }
      end
    end

    context "when workers unique_args method doesn't take parameters" do
      let(:item) do
        { 'class' => 'UniqueJobWithoutUniqueArgsParameter',
          'queue' => 'myqueue',
          'args' => [[1, 2]] }
      end
      let(:args) { ['name', 2, 'whatever' => nil, 'type' => 'test'] }

      before do
        expect(unique_args.logger)
          .to receive(:fatal)
          .with('filter_by_symbol : UniqueJobWithoutUniqueArgsParameter\'s unique_args needs at least one argument')
        expect(unique_args.logger).to receive(:fatal).with a_kind_of(ArgumentError)
      end

      it { is_expected.to eq(args) }
    end

    context 'when @worker_class does not respond_to unique_args_method' do
      let(:item) do
        { 'class' => 'UniqueJobWithNoUniqueArgsMethod',
          'queue' => 'myqueue',
          'args' => [[1, 2]] }
      end
      let(:args) { ['name', 2, 'whatever' => nil, 'type' => 'test'] }

      before do
        expect(unique_args.logger).to receive(:warn) do |&block|
          expect(block.call)
            .to eq(
              "filter_by_symbol : UniqueJobWithNoUniqueArgsMethod does not respond to filtered_args). " \
              "Returning (#{args})",
            )
        end
      end

      it { is_expected.to eq(args) }
    end

    context 'when workers unique_args method returns nil' do
      let(:item) do
        { 'class' => 'UniqueJobWithNilUniqueArgs',
          'queue' => 'myqueue',
          'args' => [[1, 2]] }
      end
      let(:args) { ['name', 2, 'whatever' => nil, 'type' => 'test'] }

      before do
        expect(unique_args.logger).to receive(:debug) do |&block|
          expect(block.call).to eq("filter_by_symbol : unique_args(#{args}) => ")
        end
      end

      it { is_expected.to eq(nil) }
    end
  end
end
