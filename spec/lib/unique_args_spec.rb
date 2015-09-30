require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::UniqueArgs do
  let(:item) { { 'class' => 'UniqueWorker', 'queue' => 'myqueue', 'args' => [[1, 2]] } }
  subject { described_class.new(item) }

  describe '#unique_args_enabled_in_worker?' do
    with_sidekiq_options_for(UniqueWorker, unique_args: :unique_args) do
      its(:unique_args_enabled_in_worker?) { is_expected.to eq(:unique_args) }
    end

    with_sidekiq_options_for(UniqueWorker, unique_args: false) do
      its(:unique_args_enabled_in_worker?) { is_expected.to eq(false) }
    end

    # For when a worker doesn't exist in the current context
    with_sidekiq_options_for('NotAWorker') do
      its(:unique_args_enabled_in_worker?) { is_expected.to eq(nil) }
    end
  end

  describe '#unique_args_enabled?' do
    with_global_config(unique_args_enabled: true) do
      with_sidekiq_options_for(UniqueWorker, unique_args: :unique_args) do
        its(:unique_args_enabled?) { is_expected.to eq(:unique_args) }
      end

      with_sidekiq_options_for(UniqueWorker, unique_args: false) do
        its(:unique_args_enabled?) { is_expected.to eq(true) }
      end
    end

    with_global_config(unique_args_enabled: false) do
      with_sidekiq_options_for(UniqueWorker, unique_args: :unique_args) do
        its(:unique_args_enabled?) { is_expected.to eq(:unique_args) }
      end

      with_sidekiq_options_for(UniqueWorker, unique_args: false) do
        its(:unique_args_enabled?) { is_expected.to eq(false) }
      end

      its(:unique_args_enabled?) { is_expected.to eq(false) }
    end
  end

  describe '#unique_on_all_queues?' do
    with_global_config(unique_args_enabled: true) do
      its(:unique_on_all_queues?) { is_expected.to eq(nil) }

      with_sidekiq_options_for(UniqueWorker, unique_args: :unique_args, unique_on_all_queues: true) do
        its(:unique_on_all_queues?) { is_expected.to eq(true) }
      end

      with_sidekiq_options_for(UniqueWorker, unique_args: :unique_args, unique_on_all_queues: false) do
        its(:unique_on_all_queues?) { is_expected.to eq(false) }
      end

      # For when a worker doesn't exist in the current context
      with_sidekiq_options_for('NotAWorker', unique_args: :unique_args, unique_on_all_queues: true) do
        its(:unique_args_enabled_in_worker?) { is_expected.to eq(nil) }
      end
    end

    with_global_config(unique_args_enabled: false) do
      its(:unique_on_all_queues?) { is_expected.to eq(nil) }

      with_sidekiq_options_for(UniqueWorker, unique_args: :unique_args, unique_on_all_queues: false) do
        its(:unique_on_all_queues?) { is_expected.to eq(false) }
      end

      with_sidekiq_options_for(UniqueWorker, unique_args: :unique_args, unique_on_all_queues: true) do
        its(:unique_on_all_queues?) { is_expected.to eq(true) }
      end

      # For when a worker doesn't exist in the current context
      with_sidekiq_options_for('NotAWorker', unique_args: :unique_args, unique_on_all_queues: true) do
        its(:unique_args_enabled_in_worker?) { is_expected.to eq(nil) }
      end
    end
  end

  describe '#filter_by_proc' do
    let(:proc) { ->(args) { args[1]['test'] } }
    before do
      allow(subject).to receive(:unique_args_method).and_return(proc)
    end

    it 'returns the value of the provided ' do
      expect(subject.filter_by_proc([1, 'test' => 'it'])).to eq('it')
    end
  end

  describe '#filter_by_symbol' do
    let(:item) { { 'class' => 'UniqueJobWithFilterMethod', 'queue' => 'myqueue', 'args' => [[1, 2]] } }
    subject { described_class.new(item) }

    it 'returns the value of the provided class method' do
      expect(subject.filter_by_symbol(['name', 2, 'whatever' => nil, 'type' => 'test'])).to eq(['name', 'test'])
    end
  end
end
