# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilAndWhileExecuting, redis: :redis, redis_db: 3 do
  include SidekiqHelpers

  let(:process_one) { described_class.new(item_one) }
  let(:runtime_one) { SidekiqUniqueJobs::Lock::WhileExecuting.new(item_one.dup) }

  let(:process_two) { described_class.new(item_two) }
  let(:runtime_two) { SidekiqUniqueJobs::Lock::WhileExecuting.new(item_two.dup) }

  let(:jid_one)      { 'jid one' }
  let(:jid_two)      { 'jid two' }
  let(:worker_class) { UntilAndWhileExecutingJob }
  let(:unique)       { :until_and_while_executing }
  let(:queue)        { :another_queue }
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
    allow(process_one).to receive(:runtime_lock).and_return(runtime_one)
    allow(process_two).to receive(:runtime_lock).and_return(runtime_two)
  end

  describe '#execute' do
    context 'when process one has locked the job' do
      before do
        expect(process_one.lock).to eq(jid_one)
        expect(process_one.locked?).to eq(true)

        expect(runtime_one.locked?).to eq(false)
        expect(runtime_two.locked?).to eq(false)
      end

      it 'process two cannot lock the job' do
        expect(process_two.lock).to eq(nil)
        expect(process_two.execute(callback)).to eq(nil)
        expect(process_two.locked?).to eq(false)
      end

      context 'when process_one executes the job' do
        it 'process two can lock the job' do
          process_one.execute(callback) do
            expect(process_one.locked?).to eq(false)
            expect(runtime_one.locked?).to eq(true)
            expect(process_two.lock).to eq(jid_two)
            process_two.delete!
          end
        end

        it 'process two cannot execute the job' do
          process_one.execute(callback) do
            unset = true
            expect(process_two.lock).to eq(jid_two)
            process_two.execute(callback) do
              unset = false
            end

            expect(unset).to eq(true)
            process_two.delete!
          end
        end

        after do
          expect(process_one.locked?).to eq(false)
          expect(process_two.locked?).to eq(false)
          expect(runtime_one.locked?).to eq(false)
          expect(runtime_two.locked?).to eq(false)
        end
      end
    end
  end
end
