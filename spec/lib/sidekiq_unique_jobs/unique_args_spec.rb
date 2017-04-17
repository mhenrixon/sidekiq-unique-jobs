require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::UniqueArgs do
  let(:item) { { 'class' => 'UntilExecutedJob', 'queue' => 'myqueue', 'args' => [[1, 2]] } }
  subject { described_class.new(item) }
  describe '#unique_digest' do
    context 'when args are empty' do
      let(:item) { { 'class' => 'WithoutArgumentJob', 'args' => [] } }
      let(:another_subject) { described_class.new(item) }

      context 'with the same unique args' do
        it 'equals to unique_digest for that item' do
          expect(subject.unique_digest).to eq(another_subject.unique_digest)
        end
      end
    end

    shared_examples 'unique digest' do
      subject { described_class.new(item_options) }
      context 'given another item' do
        let(:another_subject) { described_class.new(another_item) }

        context 'with the same unique args' do
          let(:another_item) { item_options.merge('args' => [1, 2, 'type' => 'it']) }
          it 'equals to unique_digest for that item' do
            expect(subject.unique_digest).to eq(another_subject.unique_digest)
          end
        end

        context 'with different unique args' do
          let(:another_item) { item_options.merge('args' => [1, 3, 'type' => 'that']) }
          it 'differs from unique_digest for that item' do
            expect(subject.unique_digest).not_to eq(another_subject.unique_digest)
          end
        end
      end
    end

    context 'when unique_args is a proc' do
      let(:item_options) do
        {
          'class' => 'MyUniqueJobWithFilterProc',
          'queue' => 'customqueue',
          'args' => [1, 2, 'type' => 'it'],
        }
      end

      it_behaves_like 'unique digest'
    end

    context 'when unique_args is a symbol' do
      let(:item_options) do
        {
          'class' => 'MyUniqueJobWithFilterMethod',
          'queue' => 'customqueue',
          'args' => [1, 2, 'type' => 'it'],
        }
      end

      it_behaves_like 'unique digest'
    end
  end

  describe '#unique_args_enabled?' do
    with_default_worker_options(unique: :until_executed, unique_args: ->(args) { args[1]['test'] }) do
      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args) do
        its(:unique_args_enabled?) { is_expected.to eq(:unique_args) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: false) do
        its(:unique_args_enabled?) { is_expected.to be_a(Proc) }
      end
    end

    with_default_worker_options(unique: false, unique_args: nil) do
      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args) do
        its(:unique_args_enabled?) { is_expected.to eq(:unique_args) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: false) do
        its(:unique_args_enabled?) { is_expected.to be_falsy }
      end

      its(:unique_args_enabled?) { is_expected.to be_falsy }
    end
  end

  describe '#unique_on_all_queues?' do
    with_global_config(unique_args_enabled: true) do
      its(:unique_on_all_queues?) { is_expected.to eq(nil) }

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_on_all_queues: true) do
        its(:unique_on_all_queues?) { is_expected.to eq(true) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_on_all_queues: false) do
        its(:unique_on_all_queues?) { is_expected.to be_falsy }
      end
    end

    with_global_config(unique_args_enabled: false) do
      its(:unique_on_all_queues?) { is_expected.to eq(nil) }

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_on_all_queues: false) do
        its(:unique_on_all_queues?) { is_expected.to eq(false) }
      end

      with_sidekiq_options_for(UntilExecutedJob, unique_args: :unique_args, unique_on_all_queues: true) do
        its(:unique_on_all_queues?) { is_expected.to eq(true) }
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

    with_default_worker_options(unique: :until_executed, unique_args: ->(args) { args[1]['test'] }) do
      it 'returns the value of the provided options' do
        expect(subject).to eq('it')
      end
    end
  end

  describe '#filter_by_symbol' do
    let(:unique_args) { described_class.new(item) }

    context 'when filter is a working symbol' do
      let(:item) do
        { 'class' => 'UniqueJobWithFilterMethod',
          'queue' => 'myqueue',
          'args' => [[1, 2]] }
      end

      let(:args) { ['name', 2, 'whatever' => nil, 'type' => 'test'] }
      subject { unique_args.filter_by_symbol(args) }

      it 'returns the value of the provided class method' do
        expected = %w[name test]
        expect(unique_args.logger).to receive(:debug) do |&block|
          expect(block.call).to eq("filter_by_symbol : filtered_args(#{args}) => #{expected}")
        end
        expect(subject).to eq(expected)
      end
    end

    context "when workers unique_args method doesn't take parameters"  do
      let(:item) do
        { 'class' => 'UniqueJobWithoutUniqueArgsParameter',
          'queue' => 'myqueue',
          'args' => [[1, 2]] }
      end

      let(:args) { ['name', 2, 'whatever' => nil, 'type' => 'test'] }
      subject { unique_args.filter_by_symbol(args) }

      it 'returns the value of the provided class method' do
        expect(unique_args.logger)
          .to receive(:fatal)
          .with('filter_by_symbol : UniqueJobWithoutUniqueArgsParameter\'s unique_args needs at least one argument')
        expect(unique_args.logger).to receive(:fatal).with a_kind_of(ArgumentError)

        expect(subject).to eq(args)
      end
    end

    context "when @worker_class does not respond_to unique_args_method"  do
      let(:item) do
        { 'class' => 'UniqueJobWithNoUniqueArgsMethod',
          'queue' => 'myqueue',
          'args' => [[1, 2]] }
      end

      let(:args) { ['name', 2, 'whatever' => nil, 'type' => 'test'] }
      subject { unique_args.filter_by_symbol(args) }

      it 'returns the value of the provided class method' do
        expect(unique_args.logger).to receive(:warn) do |&block|
          expect(block.call)
            .to eq("filter_by_symbol : UniqueJobWithNoUniqueArgsMethod does not respond to filtered_args). Returning (#{args})")
        end

        expect(subject).to eq(args)
      end
    end

    context "when workers unique_args method returns nil"  do
      let(:item) do
        { 'class' => 'UniqueJobWithNilUniqueArgs',
          'queue' => 'myqueue',
          'args' => [[1, 2]] }
      end

      let(:args) { ['name', 2, 'whatever' => nil, 'type' => 'test'] }
      subject { unique_args.filter_by_symbol(args) }

      it 'returns the value of the provided class method' do
        expect(unique_args.logger).to receive(:debug) do |&block|
          expect(block.call).to eq("filter_by_symbol : unique_args(#{args}) => ")
        end

        expect(subject).to eq(nil)
      end
    end
  end
end
