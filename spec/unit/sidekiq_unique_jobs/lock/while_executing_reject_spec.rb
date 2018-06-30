# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecutingReject do
  include_context 'with a stubbed locksmith'
  let(:lock)     { described_class.new(item, callback) }
  let(:callback) { -> {} }
  let(:deadset)  { instance_spy(Sidekiq::DeadSet) }
  let(:payload)  { instance_spy('payload') }
  let(:item) do
    { 'jid' => 'maaaahjid',
      'class' => 'WhileExecutingRejectJob',
      'unique' => 'while_executing_reject',
      'args' => [%w[array of arguments]] }
  end

  before do
    allow(lock).to receive(:deadset).and_return(deadset)
    allow(lock).to receive(:unlock)
    allow(lock).to receive(:payload).and_return(payload)
  end

  describe '#lock' do
    subject { lock.lock }

    it { is_expected.to eq(true) }
  end

  describe '#execute' do
    subject(:execute) { lock.execute }

    let(:token) { nil }

    before do
      allow(locksmith).to receive(:lock).with(0).and_return(token)
      allow(lock).to receive(:with_cleanup).and_yield
    end

    context 'when lock succeeds' do
      let(:token) { 'a token' }

      it 'processes the job' do
        execute
        expect(lock).to have_received(:with_cleanup)
      end
    end

    context 'when lock fails' do
      let(:token) { nil }

      it 'rejects the job' do
        expect(lock).to receive(:reject)
        execute

        expect(lock).not_to have_received(:with_cleanup)
      end
    end
  end

  describe '#send_to_deadset' do
    subject(:send_to_deadset) { lock.send_to_deadset }

    context 'when deadset_kill?' do
      before { allow(lock).to receive(:deadset_kill?).and_return(true) }

      it 'calls deadset_kill' do
        expect(lock).to receive(:deadset_kill)
        send_to_deadset
      end
    end

    context 'when not deadset_kill?' do
      before { allow(lock).to receive(:deadset_kill?).and_return(false) }

      it 'calls push_to_deadset' do
        expect(lock).to receive(:push_to_deadset)
        send_to_deadset
      end
    end
  end

  describe '#deadset_kill' do
    subject(:deadset_kill) { lock.deadset_kill }

    context 'when kill_with_options?' do
      before { allow(lock).to receive(:kill_with_options?).and_return(true) }

      it 'calls kill_job_with_options' do
        expect(lock).to receive(:kill_job_with_options)
        deadset_kill
      end
    end

    context 'when not kill_with_options?' do
      before { allow(lock).to receive(:kill_with_options?).and_return(false) }

      it 'calls kill_job_without_options' do
        expect(lock).to receive(:kill_job_without_options)
        deadset_kill
      end
    end
  end

  describe '#kill_job_with_options' do
    subject(:kill_job_with_options) { lock.kill_job_with_options }

    it 'calls deadset.kill with options hash', sidekiq_ver: '>= 5.1.0' do
      expect(deadset).to receive(:kill).with(payload, notify_failure: false)
      kill_job_with_options
    end
  end

  describe '#kill_job_without_options' do
    subject(:kill_job_without_options) { lock.kill_job_without_options }

    it 'calls deadset.kill without options hash', sidekiq_ver: '>= 5.0.0 && < 5.1.0' do
      expect(deadset).to receive(:kill).with(payload)
      kill_job_without_options
    end
  end
end
