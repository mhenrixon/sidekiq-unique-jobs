require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::QueueLockTimeoutCalculator do
  shared_context 'generic unscheduled job' do
    subject { described_class.new('class' => 'JustAWorker') }
  end

  describe 'public api' do
    it_behaves_like 'generic unscheduled job' do
      it { is_expected.to respond_to(:seconds) }
      it { is_expected.to respond_to(:queue_lock_expiration) }
    end
  end

  describe '.for_item' do
    it 'initializes a new calculator' do
      expect(described_class).to receive(:new).with('WAT')
      described_class.for_item('WAT')
    end
  end

  describe '#seconds' do
    subject { described_class.new(nil) }

    before do
      allow(subject).to receive(:time_until_scheduled).and_return(10)
      allow(subject).to receive(:queue_lock_expiration).and_return(9)
    end
    its(:seconds) { is_expected.to eq(19) }
  end

  describe '#queue_lock_expiration' do
    context 'using default unique_expiration' do
      subject { described_class.new(nil) }
      before { allow(subject).to receive(:worker_class_queue_lock_expiration).and_return(nil) }

      its(:queue_lock_expiration) { is_expected.to eq(1_800) }
    end

    context 'using specified sidekiq option unique_expiration' do
      subject { described_class.new(nil) }
      before { allow(subject).to receive(:worker_class_queue_lock_expiration).and_return(9) }

      its(:queue_lock_expiration) { is_expected.to eq(9) }
    end
  end
end
