require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::QueueLockTimeoutCalculator do
  shared_context 'generic unscheduled job' do
    subject { described_class.new('class' => 'JustAWorker') }
  end

  describe 'public api' do
    it_behaves_like 'generic unscheduled job' do
      it { is_expected.to respond_to(:worker_class_queue_lock_expiration) }
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
    subject { described_class.new(nil) }

    before do
      allow(subject).to receive(:time_until_scheduled).and_return(10)
      allow(subject).to receive(:queue_lock_expiration).and_return(9)
    end
    its(:seconds) { is_expected.to eq(19) }
  end

  describe '#queue_lock_expiration' do
    it_behaves_like 'generic unscheduled job' do
      its(:queue_lock_expiration) { is_expected.to eq(SidekiqUniqueJobs.config.default_queue_lock_expiration) }
    end

    subject { described_class.new('class' => 'MyUniqueJob') }
    its(:queue_lock_expiration) { is_expected.to eq(7_200) }
  end

end
