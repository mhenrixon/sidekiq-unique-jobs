# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Timeout::QueueLock do
  let(:calculator)      { described_class.new(item) }

  let(:lock_expiration) { nil }
  let(:lock_timeout)    { nil }
  let(:item) do
    {
      'class' => 'JustAWorker',
      'lock_expiration' => lock_expiration,
      'lock_timeout' => lock_timeout,
    }
  end

  describe 'public api' do
    subject { calculator }
    it { is_expected.to respond_to(:lock_expiration) }
    it { is_expected.to respond_to(:lock_timeout) }
  end

  describe '#lock_expiration' do
    subject { calculator.lock_expiration }

    let(:time_until_scheduled)               { 10 }
    let(:worker_class_lock_expiration)       { nil }
    let(:worker_class_queue_lock_expiration) { nil }

    before do
      allow(calculator).to receive(:time_until_scheduled).and_return(time_until_scheduled)
      allow(calculator).to receive(:worker_class_lock_expiration).and_return(worker_class_lock_expiration)
      allow(calculator).to receive(:worker_class_queue_lock_expiration).and_return(worker_class_queue_lock_expiration)
    end

    context 'when argument hash contains `lock_expiration: 10' do
      let(:lock_expiration) { 10 }

      it { is_expected.to eq(20) }
    end

    context 'when worker is configured with `lock_expiration: 20`' do
      let(:worker_class_lock_expiration) { 20 }

      context 'when item["lock_expiration"] is nil' do
        it { is_expected.to eq(nil) }
      end

      context 'when item["lock_expiration"] is not present' do
        let(:item) do
          {
            'class' => 'JustAWorker',
            'lock_timeout' => lock_timeout,
          }
        end

        it { is_expected.to eq(30) }
      end
    end

    context 'when worker is configured with `queu_lock_expiration: 30`' do
      let(:worker_class_queue_lock_expiration) { 30 }

      context 'when item["lock_expiration"] is nil' do
        it { is_expected.to eq(nil) }
      end

      context 'when item["lock_expiration"] is not present' do
        let(:item) do
          {
            'class' => 'JustAWorker',
            'lock_timeout' => lock_timeout,
          }
        end
        it { is_expected.to eq(40) }
      end
    end

    context 'without further configuration' do
      context 'when item["lock_expiration"] is nil' do
        it { is_expected.to eq(nil) }
      end

      context 'when item["lock_expiration"] is not present' do
        let(:item) do
          {
            'class' => 'JustAWorker',
            'lock_timeout' => lock_timeout,
          }
        end

        it { is_expected.to eq(nil) }
      end
    end
  end
end
