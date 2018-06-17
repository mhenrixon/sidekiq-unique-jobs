# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilExecuted do
  let(:lock) { described_class.new(item) }
  let(:item) do
    {
      'jid' => 'maaaahjid',
      'class' => 'UntilExecutedJob',
      'unique' => 'until_executed',
    }
  end

  describe '#execute' do
    subject(:execute) { lock.execute(empty_callback) }

    let(:empty_callback) { -> {} }

    context 'when yield fails with Sidekiq::Shutdown' do
      before do
        allow(lock).to receive(:after_yield_yield) { raise Sidekiq::Shutdown }
        allow(lock).to receive(:unlock).and_return(true)
      end

      it 'logs a helpful error message' do
        error_message = 'the unique_key: uniquejobs:a1e5ccafbc77b234e8f8aaedde3f706e needs to be unlocked manually'
        expect(Sidekiq.logger).to receive(:fatal).with(error_message)

        expect { execute }.to raise_error(Sidekiq::Shutdown)
      end

      it 'raises Sidekiq::Shutdown' do
        expect(lock).not_to receive(:unlock)
        expect(empty_callback).not_to receive(:call)

        expect { execute }.to raise_error(Sidekiq::Shutdown)
      end
    end

    context 'when yield fails with other errors' do
      before do
        allow(lock).to receive(:after_yield_yield) { raise 'Hell' }
      end

      it 'raises "Hell"' do
        expect(lock).to receive(:unlock).and_return(true)
        expect(empty_callback).to receive(:call)

        expect { execute }.to raise_error('Hell')
      end
    end
  end
end
