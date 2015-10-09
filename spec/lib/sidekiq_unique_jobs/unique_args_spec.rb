require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::UniqueArgs do
  let(:item) { { 'class' => 'UntilExecutedJob', 'queue' => 'myqueue', 'args' => [[1, 2]] } }
  subject { described_class.new(item) }

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
    context 'without any default worker options configured' do
      before do
        allow(subject).to receive(:unique_args_method).and_return(filter)
      end

      it 'returns the value of theoptions hash ' do
        expect(subject.filter_by_proc([1, 'test' => 'it'])).to eq('it')
      end
    end

    with_default_worker_options(unique: :until_executed, unique_args: ->(args) { args[1]['test'] }) do
      it 'returns the value of the provided options' do
        expect(subject.filter_by_proc([1, 'test' => 'it'])).to eq('it')
      end
    end
  end

  describe '#filter_by_symbol' do
    let(:item) do
      { 'class' => 'UniqueJobWithFilterMethod',
        'queue' => 'myqueue',
        'args' => [[1, 2]] }
    end
    subject { described_class.new(item) }

    it 'returns the value of the provided class method' do
      expect(subject.filter_by_symbol(['name', 2, 'whatever' => nil, 'type' => 'test']))
        .to eq(%w(name test))
    end
  end
end
