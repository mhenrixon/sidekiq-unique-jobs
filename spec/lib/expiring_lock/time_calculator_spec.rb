require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::ExpiringLock::TimeCalculator do
  include ActiveSupport::Testing::TimeHelpers
  shared_context 'undefined worker class' do
    subject { described_class.new('class' => 'test') }
  end

  shared_context 'item not scheduled' do
    subject { described_class.new('class' => 'MyUniqueWorker') }
  end

  describe 'public api' do
    subject { described_class.new(nil) }
    it { is_expected.to respond_to(:time_until_scheduled) }
    it { is_expected.to respond_to(:unique_job_expiration) }
    it { is_expected.to respond_to(:worker_class_unique_job_expiration) }
    it { is_expected.to respond_to(:worker_class) }
    it { is_expected.to respond_to(:seconds) }
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
      allow(subject).to receive(:unique_job_expiration).and_return(9)
    end
    its(:seconds) { is_expected.to eq(19) }
  end

  describe '#time_until_scheduled' do
    it_behaves_like 'item not scheduled' do
      its(:time_until_scheduled) { is_expected.to eq(0) }
    end

    subject { described_class.new('class' => 'MyUniqueWorker', 'at' => schedule_time) }
    let(:schedule_time) { 1.day.from_now.to_i }
    let(:now_in_utc) { Time.now.utc.to_i }

    its(:time_until_scheduled) do
      travel_to(Time.at(now_in_utc)) do
        is_expected.to eq(schedule_time - now_in_utc)
      end
    end
  end

  describe '#unique_job_expiration' do
    it_behaves_like 'undefined worker class' do
      its(:unique_job_expiration) { is_expected.to eq(SidekiqUniqueJobs.config.default_expiration) }
    end

    subject { described_class.new('class' => 'MyUniqueWorker') }
    its(:unique_job_expiration) { is_expected.to eq(7_200) }
  end

  describe '#worker_class_unique_job_expiration' do
    it_behaves_like 'undefined worker class' do
      its(:worker_class_unique_job_expiration) { is_expected.to eq(nil) }
    end

    subject { described_class.new('class' => 'MyUniqueWorker') }
    its(:worker_class_unique_job_expiration) { is_expected.to eq(7_200) }
  end

  describe '#worker_class' do
    it_behaves_like 'undefined worker class' do
      its(:worker_class) { is_expected.to eq('test') }
    end

    subject { described_class.new('class' => 'MyWorker') }
    its(:worker_class) { is_expected.to eq(MyWorker) }
  end
end
