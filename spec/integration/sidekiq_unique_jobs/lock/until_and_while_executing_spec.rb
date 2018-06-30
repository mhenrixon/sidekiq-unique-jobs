# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilAndWhileExecuting, redis: :redis, redis_db: 3 do
  include SidekiqHelpers

  let(:process_one) { described_class.new(item_one, callback) }
  let(:runtime_one) { SidekiqUniqueJobs::Lock::WhileExecuting.new(item_one.dup, callback) }

  let(:process_two) { described_class.new(item_two, callback) }
  let(:runtime_two) { SidekiqUniqueJobs::Lock::WhileExecuting.new(item_two.dup, callback) }

  let(:jid_one)      { 'jid one' }
  let(:jid_two)      { 'jid two' }
  let(:lock_timeout) { nil }
  let(:sleepy_time)  { 0 }
  let(:worker_class) { UntilAndWhileExecutingJob }
  let(:unique)       { :until_and_while_executing }
  let(:queue)        { :another_queue }
  let(:args)         { [sleepy_time] }
  let(:callback)     { -> {} }
  let(:item_one) do
    { 'jid' => jid_one,
      'class' => worker_class.to_s,
      'queue' => queue,
      'unique' => unique,
      'args' => args,
      'lock_timeout' => lock_timeout }
  end
  let(:item_two) do
    item_one.merge('jid' => jid_two)
  end

  before do
    allow(process_one).to receive(:runtime_lock).and_return(runtime_one)
    allow(process_two).to receive(:runtime_lock).and_return(runtime_two)
  end

  describe '#execute' do
    before do
      expect(process_one.lock).to eq(jid_one)
      expect(process_one.locked?).to eq(true)

      expect(runtime_one.locked?).to eq(false)
      expect(runtime_two.locked?).to eq(false)
    end

    it 'process two cannot lock the job' do
      expect(process_two.lock).to eq(nil)
      expect(process_two.execute).to eq(nil)
      expect(process_two.locked?).to eq(false)
    end

    context 'when timeout is 0' do
      let(:lock_timeout) { 0 }

      context 'when process_one executes the job in 0 seconds' do
        context 'when process_one executes the job' do # rubocop:disable RSpec/NestedGroups
          it 'process two can lock the job' do
            process_one.execute do
              expect(process_one.locked?).to eq(false)
              expect(runtime_one.locked?).to eq(true)
              expect(process_two.lock).to eq(jid_two)
              process_two.delete!
            end
          end

          it 'process two cannot execute the job' do
            process_one.execute do
              unset = true
              expect(process_two.lock).to eq(jid_two)
              process_two.execute do
                unset = false
              end

              expect(unset).to eq(true)
              process_two.delete!
            end
          end
        end
      end

      context 'when process_one executes the job in 1 seconds' do
        let(:sleepy_time) { 1 }

        it 'process two can lock the job' do
          process_one.execute do
            expect(process_one.locked?).to eq(false)
            expect(runtime_one.locked?).to eq(true)
            expect(process_two.lock).to eq(jid_two)
            process_two.delete!
          end
        end

        it 'process two cannot execute the job' do
          process_one.execute do
            unset = true
            expect(process_two.lock).to eq(jid_two)
            process_two.execute do
              unset = false
            end

            expect(unset).to eq(true)
            process_two.delete!
          end
        end
      end
    end

    context 'when timeout is 1' do
      let(:lock_timeout) { 1 }

      context 'when process_one executes the job' do
        it 'process two can lock the job' do
          process_one.execute do
            expect(process_one.locked?).to eq(false)
            expect(runtime_one.locked?).to eq(true)
            expect(process_two.lock).to eq(jid_two)
            process_two.delete!
          end
        end

        it 'process two cannot execute the job' do
          process_one.execute do
            unset = true
            expect(process_two.lock).to eq(jid_two)
            process_two.execute do
              unset = false
            end

            expect(unset).to eq(true)
            process_two.delete!
          end
        end
      end
    end

    context 'when process_one executes the job in 1 seconds' do
      let(:sleepy_time) { 1 }

      it 'process two can lock the job' do
        process_one.execute do
          expect(process_one.locked?).to eq(false)
          expect(runtime_one.locked?).to eq(true)
          expect(process_two.lock).to eq(jid_two)
          process_two.delete!
        end
      end

      it 'process two cannot execute the job' do
        process_one.execute do
          unset = true
          expect(process_two.lock).to eq(jid_two)
          process_two.execute do
            unset = false
          end

          expect(unset).to eq(true)
          process_two.delete!
        end
      end
    end

    # after do
    #   expect(process_one.locked?).to eq(false)
    #   expect(process_two.locked?).to eq(false)
    #   expect(runtime_one.locked?).to eq(false)
    #   expect(runtime_two.locked?).to eq(false)
    # end
  end
end
