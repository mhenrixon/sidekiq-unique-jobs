require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::RunLockTimeoutCalculator do
  shared_context 'generic unscheduled job' do
    subject { described_class.new('class' => 'JustAWorker') }
  end

  describe 'public api' do
    it_behaves_like 'generic unscheduled job' do
      it { is_expected.to respond_to(:seconds) }
    end
  end

  describe '.for_item' do
    it 'initializes a new calculator' do
      expect(described_class).to receive(:new).with('WAT')
      described_class.for_item('WAT')
    end
  end

  describe '#seconds' do
    context 'using default run_lock_expiration' do
      subject { described_class.new(nil) }
      before { allow(subject).to receive(:worker_class_run_lock_expiration).and_return(9) }

      its(:seconds) { is_expected.to eq(9) }
    end

    context 'using specified sidekiq option run_lock_expiration' do
      subject { described_class.new(nil) }
      before { allow(subject).to receive(:worker_class_run_lock_expiration).and_return(nil) }

      its(:seconds) { is_expected.to eq(60) }
    end
  end
end
