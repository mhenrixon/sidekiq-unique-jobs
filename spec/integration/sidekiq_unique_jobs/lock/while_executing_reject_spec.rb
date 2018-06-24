# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecutingReject, redis: :redis do
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

      it 'moves subsequent jobs to dead queue' do
        process_one.execute(callback) do
          expect(dead_count).to eq(0)
          expect { process_two.execute(callback) {} }
            .to change { dead_count }.from(0).to(1)
        end
      end
    end
  end
end
