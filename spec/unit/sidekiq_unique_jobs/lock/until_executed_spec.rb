# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilExecuted, redis: :redis do
  describe '#execute' do
    subject(:execute) { lock.execute(empty_callback) }

    let(:lock)           { described_class.new(item) }
    let(:empty_callback) { -> {} }
    let(:item) do
      {
        'jid' => 'maaaahjid',
        'class' => 'UntilExecutedJob',
        'unique' => 'until_executed',
      }
    end

    context 'when yield fails with Sidekiq::Shutdown' do
      before do
        allow(lock).to receive(:after_yield_yield) { raise Sidekiq::Shutdown }
        allow(lock).to receive(:unlock).and_return(true)
        expect(lock).not_to receive(:unlock)
        expect(Sidekiq.logger).to receive(:fatal)
          .with('the unique_key: uniquejobs:a1e5ccafbc77b234e8f8aaedde3f706e needs to be unlocked manually')

        expect(empty_callback).not_to receive(:call)
      end

      specify { expect { execute }.to raise_error(Sidekiq::Shutdown) }
    end

    context 'when yield fails with other errors' do
      before do
        allow(lock).to receive(:after_yield_yield) { raise 'Hell' }
        expect(lock).to receive(:unlock).and_return(true)
        expect(empty_callback).to receive(:call)
      end

      specify { expect { execute }.to raise_error('Hell') }
    end
  end
end
