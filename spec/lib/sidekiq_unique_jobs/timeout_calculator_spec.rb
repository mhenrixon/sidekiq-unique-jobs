# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::TimeoutCalculator do
  let(:calculator)    { described_class.new('class' => worker_class, 'at' => schedule_time) }
  let(:worker_class)  { 'MyUniqueJob' }
  let(:schedule_time) { nil }

  describe 'public api' do
    subject { described_class.new(nil) }

    it { is_expected.to respond_to(:time_until_scheduled) }
    it { is_expected.to respond_to(:worker_class_queue_lock_expiration) }
    it { is_expected.to respond_to(:worker_class_run_lock_expiration) }
    it { is_expected.to respond_to(:worker_class) }
    it { is_expected.to respond_to(:seconds) }
  end

  describe '.for_item' do
    it 'initializes a new calculator' do
      expect(described_class).to receive(:new).with('WAT')
      described_class.for_item('WAT')
    end
  end

  describe '#time_until_scheduled' do
    subject { calculator.time_until_scheduled }

    context 'when not scheduled' do
      it { is_expected.to eq(0) }
    end

    context 'when scheduled' do
      let(:schedule_time) { Time.now.utc.to_i + 24 * 60 * 60 }
      let(:now_in_utc)    { Time.now.utc.to_i }

      it do
        Timecop.travel(Time.at(now_in_utc)) do
          is_expected.to be_within(1).of(schedule_time - now_in_utc)
        end
      end
    end
  end

  describe '#worker_class_queue_lock_expiration' do
    subject { calculator.worker_class_queue_lock_expiration }

    it { is_expected.to eq(7_200) }
  end

  describe '#worker_class_run_lock_expiration' do
    subject { calculator.worker_class_run_lock_expiration }
    let(:worker_class) { 'LongRunningJob' }

    it { is_expected.to eq(7_200) }
  end

  describe '#worker_class' do
    subject { calculator.worker_class }

    let(:worker_class) { 'MyUniqueJob' }

    it { is_expected.to eq(MyUniqueJob) }

    context 'when worker class is a constant' do
      let(:worker_class) { 'MissingWorker' }

      it { is_expected.to eq('MissingWorker') }
    end

    context 'when worker class is not a constant' do
      let(:worker_class) { 'missing_worker' }

      it do
        expect { subject }.to raise_error(NameError, 'wrong constant name missing_worker')
      end
    end
  end
end
