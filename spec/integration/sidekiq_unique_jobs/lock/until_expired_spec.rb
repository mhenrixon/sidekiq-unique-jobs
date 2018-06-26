# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilExpired, redis: :redis do
  include SidekiqHelpers

  let(:process_one) { described_class.new(item_one) }
  let(:process_two) { described_class.new(item_two) }

  let(:jid_one)      { 'jid one' }
  let(:jid_two)      { 'jid two' }
  let(:worker_class) { UntilExpiredJob }
  let(:unique)       { :until_expired }
  let(:queue)        { :rejecting }
  let(:args)         { %w[array of arguments] }
  let(:callback)     { -> {} }
  let(:item_one) do
    { 'jid' => jid_one,
      'class' => worker_class.to_s,
      'queue' => queue,
      'unique' => unique,
      'args' => args }
  end
  let(:item_two) do
    { 'jid' => jid_two,
      'class' => worker_class.to_s,
      'queue' => queue,
      'unique' => unique,
      'args' => args }
  end

  before do
    allow(callback).to receive(:call).and_call_original
  end

  describe '#execute' do
    it 'process one can be locked' do
      expect(process_one.lock).to eq(jid_one)
      expect(process_one.locked?).to eq(true)
    end

    context 'when process one has locked the job' do
      before do
        process_one.lock
      end

      it 'process two cannot achieve a lock' do
        expect(process_two.lock).to eq(nil)
      end

      it 'process two cannot execute the lock' do
        unset = true
        process_two.execute(callback) do
          unset = false
        end

        expect(unset).to eq(true)
      end

      it 'process one can execute the job' do
        set = false
        process_one.execute(callback) do
          set = true
        end

        expect(set).to eq(true)
      end

      it 'the job is still locked after executing' do
        process_one.execute(callback) {}

        expect(process_one.locked?).to eq(true)
      end

      it 'calls back' do
        process_one.execute(callback) do
          # NO OP
        end

        expect(callback).to have_received(:call)
      end

      it 'callbacks are only called once (for the locked process)' do
        process_one.execute(callback) do
          process_two.execute(callback) {}
        end

        expect(callback).to have_received(:call).once
      end
    end
  end

  describe '#unlock' do
    context 'when lock is locked' do
      before { process_one.lock }

      it 'keeps the lock even when unlocking' do
        expect(process_one.unlock).to eq(true)
        expect(process_one.locked?).to eq(true)
      end
    end

    it { expect(process_one.unlock).to eq(true) }
  end
end
