# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilExecuted do
  include_context 'with a stubbed locksmith'
  let(:item) do
    {
      'jid' => 'maaaahjid',
      'class' => 'UntilExecutedJob',
      'unique' => 'until_executed',
      'args' => %w[one two],
    }
  end

  describe '#execute' do
    let(:empty_callback) { -> {} }
    let(:error_message) { 'the unique_key: uniquejobs:1b9f2f0624489ccf4e07ac88beae6ce0 needs to be unlocked manually' }

    before do
      allow(lock).to receive(:unlock).and_return(true)
    end

    context 'when yield fails with Sidekiq::Shutdown' do
      subject(:execute) { lock.execute(empty_callback) { fail Sidekiq::Shutdown, 'testing' } }

      it 'logs a helpful error message' do
        expect(Sidekiq.logger).to receive(:fatal).with(error_message)

        expect { execute }.to raise_error(Sidekiq::Shutdown)
      end

      it 'raises Sidekiq::Shutdown' do
        expect(lock).not_to receive(:unlock)
        expect(empty_callback).not_to receive(:call)

        expect { execute }.to raise_error(Sidekiq::Shutdown, 'testing')
      end
    end

    context 'when yield fails with other errors' do
      subject(:execute) { lock.execute(empty_callback) { raise 'HELL' } }

      let(:locked?) { nil }

      before do
        allow(lock).to receive(:locked?).and_return(locked?)
      end

      it 'raises "HELL"' do
        expect(lock).to receive(:unlock).and_return(true)

        expect { execute }.to raise_error('HELL')
      end

      context 'when lock is locked?' do
        let(:locked?) { true }

        it 'logs a helpful error message' do
          expect(Sidekiq.logger).to receive(:fatal).with(error_message)
          expect { execute }.to raise_error('HELL')
        end
      end

      context 'when lock is not locked?' do
        let(:locked?) { false }

        it 'calls back' do
          expect(empty_callback).to receive(:call)

          expect { execute }.to raise_error('HELL')
        end
      end
    end
  end
end
