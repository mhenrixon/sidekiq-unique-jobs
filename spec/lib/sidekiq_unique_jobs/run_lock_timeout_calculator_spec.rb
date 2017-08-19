# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::RunLockTimeoutCalculator do
  subject { calculator }

  let(:calculator) { described_class.new(args) }
  let(:args)       { { 'class' => 'JustAWorker' } }

  it { is_expected.to respond_to(:seconds) }

  describe '.for_item' do
    subject { described_class.for_item('WAT') }

    it 'initializes a new calculator' do
      expect(described_class).to receive(:new).with('WAT')
      subject
    end
  end

  describe '#seconds' do
    subject { calculator.seconds }

    before do
      allow(calculator).to receive(:worker_class_run_lock_expiration)
        .and_return(expiration)
    end

    context 'when worker_class_run_lock_expiration is configured' do
      let(:args)       { nil }
      let(:expiration) { 9 }

      it { is_expected.to eq(9) }
    end

    context 'when worker_class_run_lock_expiration is not configured' do
      let(:args)       { nil }
      let(:expiration) { nil }

      it { is_expected.to eq(60) }
    end
  end
end
