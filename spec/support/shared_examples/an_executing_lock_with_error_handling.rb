# frozen_string_literal: true

RSpec.shared_examples 'an executing lock with error handling' do
  subject(:execute) { lock.execute(empty_callback, &block) }

  let(:empty_callback)    { -> {} }
  let(:block)             { -> {} }
  let(:error_message)     { "the unique_key: #{item['unique_digest']} needs to be unlocked manually" }
  let(:initially_locked?) { true }
  let(:locked?)           { true }

  before do
    allow(lock).to receive(:locked?).and_return(initially_locked?, locked?)
    allow(lock).to receive(:unlock).and_return(true)
    allow(lock).to receive(:delete).and_return(true)
    allow(empty_callback).to receive(:call).and_call_original
    allow(block).to receive(:call).and_call_original
    allow(lock).to receive(:log_warn)
    allow(lock).to receive(:log_fatal)
  end

  context 'when yield fails with Sidekiq::Shutdown' do
    let(:block) { -> { fail Sidekiq::Shutdown, 'testing' } }

    it 'logs a helpful error message' do
      expect { execute }.to raise_error(Sidekiq::Shutdown)

      expect(lock).to have_received(:log_fatal).with(error_message)
    end

    it 'raises Sidekiq::Shutdown' do
      expect { execute }.to raise_error(Sidekiq::Shutdown, 'testing')

      expect(lock).not_to have_received(:unlock)
      expect(empty_callback).not_to have_received(:call)
    end
  end

  context 'when yield fails with other errors' do
    let(:block)   { -> { raise 'HELL' } }
    let(:locked?) { nil }

    it 'raises "HELL"' do
      expect { execute }.to raise_error('HELL')

      expect(lock).to have_received(:unlock)
    end

    context 'when lock is locked?' do
      let(:locked?) { true }

      it 'logs a helpful error message' do
        expect { execute }.to raise_error('HELL')

        expect(lock).to have_received(:log_fatal).with(error_message)
      end
    end
  end
end
