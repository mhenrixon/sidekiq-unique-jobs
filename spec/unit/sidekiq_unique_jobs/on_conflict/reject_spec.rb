# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::OnConflict::Reject do
  include_context 'with a stubbed locksmith'
  let(:strategy) { described_class.new(item) }
  let(:deadset)  { instance_spy(Sidekiq::DeadSet) }
  let(:payload)  { instance_spy('payload') }
  let(:item) do
    { 'jid' => 'maaaahjid',
      'class' => 'WhileExecutingRejectJob',
      'lock' => 'while_executing_reject',
      'args' => [%w[array of arguments]] }
  end

  before do
    allow(strategy).to receive(:deadset).and_return(deadset)
    allow(strategy).to receive(:payload).and_return(payload)
  end

  describe '#replace?' do
    subject { strategy.replace? }

    it { is_expected.to eq(false) }
  end

  describe '#send_to_deadset' do
    subject(:send_to_deadset) { strategy.send_to_deadset }

    context 'when deadset_kill?' do
      before { allow(strategy).to receive(:deadset_kill?).and_return(true) }

      it 'calls deadset_kill' do
        expect(strategy).to receive(:deadset_kill)
        send_to_deadset
      end
    end

    context 'when not deadset_kill?' do
      before { allow(strategy).to receive(:deadset_kill?).and_return(false) }

      it 'calls push_to_deadset' do
        expect(strategy).to receive(:push_to_deadset)
        send_to_deadset
      end
    end
  end

  describe '#deadset_kill' do
    subject(:deadset_kill) { strategy.deadset_kill }

    context 'when kill_with_options?' do
      before { allow(strategy).to receive(:kill_with_options?).and_return(true) }

      it 'calls kill_job_with_options' do
        expect(strategy).to receive(:kill_job_with_options)
        deadset_kill
      end
    end

    context 'when not kill_with_options?' do
      before { allow(strategy).to receive(:kill_with_options?).and_return(false) }

      it 'calls kill_job_without_options' do
        expect(strategy).to receive(:kill_job_without_options)
        deadset_kill
      end
    end
  end

  describe '#kill_job_with_options' do
    subject(:kill_job_with_options) { strategy.kill_job_with_options }

    it 'calls deadset.kill with options hash', sidekiq_ver: '>= 5.1.0' do
      expect(deadset).to receive(:kill).with(payload, notify_failure: false)
      kill_job_with_options
    end
  end

  describe '#kill_job_without_options' do
    subject(:kill_job_without_options) { strategy.kill_job_without_options }

    it 'calls deadset.kill without options hash', sidekiq_ver: '>= 5.0.0 && < 5.1.0' do
      expect(deadset).to receive(:kill).with(payload)
      kill_job_without_options
    end
  end
end
