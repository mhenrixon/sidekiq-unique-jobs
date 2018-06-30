# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilExecuted do
  include_context 'with a stubbed locksmith'
  let(:lock)     { described_class.new(item, callback) }
  let(:callback) { -> {} }
  let(:item) do
    {
      'jid' => 'maaaahjid',
      'class' => 'UntilExecutedJob',
      'unique' => 'until_executed',
      'args' => %w[one two],
    }
  end

  describe '#execute' do
    it_behaves_like 'an executing lock with error handling' do
      context 'when not initially locked?' do
        let(:initially_locked?) { false }

        it 'returns without yielding' do
          execute

          expect(callback).not_to have_received(:call)
          expect(block).not_to have_received(:call)
        end
      end

      context 'when lock is not locked?' do
        let(:block)   { -> { raise 'HELL' } }
        let(:locked?) { nil }

        it 'calls back' do
          expect { execute }.to raise_error('HELL')

          expect(callback).to have_received(:call)
        end
      end

      context 'when callback raises error' do
        let(:callback) { -> { raise 'CallbackError' } }
        let(:locked?)  { false }

        it 'logs a warning' do
          expect { execute }.to raise_error('CallbackError')

          expect(lock).to have_received(:log_warn).with('The lock for uniquejobs:1b9f2f0624489ccf4e07ac88beae6ce0 has been released but the #after_unlock callback failed!')
        end
      end
    end
  end
end
