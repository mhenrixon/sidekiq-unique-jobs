# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecuting, redis: :redis do
  include SidekiqHelpers

  let(:process_one) { described_class.new(item_one) }
  let(:process_two) { described_class.new(item_two) }

  let(:jid_one)      { 'jid one' }
  let(:jid_two)      { 'jid two' }
  let(:worker_class) { WhileExecutingRejectJob }
  let(:unique)       { :while_executing_reject }
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
    it 'does not lock jobs' do
      expect(process_one.lock).to eq(true)
      expect(process_one.locked?).to eq(false)

      expect(process_two.lock).to eq(true)
      expect(process_two.locked?).to eq(false)
    end

    context 'when job is executing' do
      it 'locks the process' do
        process_one.execute(callback) do
          expect(process_one.locked?).to eq(true)
        end
      end

      it 'calls back' do
        process_one.execute(callback) do
          # NO OP
        end
        expect(callback).to have_received(:call)
      end

      it 'prevents other processes from executing' do
        process_one.execute(callback) do
          expect(process_two.lock).to eq(true)
          expect(process_two.locked?).to eq(false)
          unset = true
          process_two.execute(callback) do
            unset = false
          end
          expect(unset).to eq(true)
        end

        expect(callback).to have_received(:call).once
      end
    end
  end
end
