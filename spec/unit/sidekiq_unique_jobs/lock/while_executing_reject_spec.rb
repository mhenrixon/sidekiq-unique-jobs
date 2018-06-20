# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecutingReject do
  include_context 'with a stubbed locksmith'

  let(:item) do
    { 'jid' => 'maaaahjid',
      'class' => 'WhileExecutingRejectJob',
      'unique' => 'while_executing_reject',
      'args' => [%w[array of arguments]] }
  end
  let(:empty_callback) { -> {} }
  let(:deadset)        { instance_spy(Sidekiq::DeadSet) }
  let(:payload)        { instance_spy('payload') }

  before do
    allow(lock).to receive(:deadset).and_return(deadset)
    allow(lock).to receive(:payload).and_return(payload)
  end

  describe '#lock' do
    subject { lock.lock }

    it { is_expected.to eq(true) }
  end

  describe '#execute' do
    subject(:execute) { lock.execute(empty_callback) }

    before do
      allow(locksmith).to receive(:wait).with(0).and_return(token)
      allow(locksmith).to receive(:signal).with(token)
    end

    context 'when lock is successful' do
      let(:token) { 'a' }

      it 'yields control to the caller' do
        allow(locksmith).to receive(:wait).with(0).and_return(token)
        expect { |block| lock.execute(empty_callback, &block) }.to yield_control
      end

      it 'unlocks properly' do
        expect(locksmith).to receive(:signal).with(token)
        execute
      end

      it 'calls the callback' do
        expect(empty_callback).to receive(:call)
        execute
      end
    end

    context 'when lock fails' do
      let(:token) { nil }

      it 'rejects the job' do
        expect(lock).to receive(:reject)
        execute
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
