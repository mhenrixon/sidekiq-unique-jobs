# frozen_string_literal: true

RSpec.shared_examples 'an executing lock with error handling' do
  subject(:execute) { lock.execute(empty_callback, &block) }

  let(:empty_callback) { -> {} }
  let(:block)          { -> {} }
  let(:error_message)  { "the unique_key: #{item['unique_digest']} needs to be unlocked manually" }

  before do
    allow(lock).to receive(:unlock).and_return(true)
  end

  context 'when yield fails with Sidekiq::Shutdown' do
    let(:block) { -> { fail Sidekiq::Shutdown, 'testing' } }

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
    let(:block) { -> { raise 'HELL' } }

    let(:locked?) { nil }

    before do
      allow(lock).to receive(:locked?).and_return(locked?)
      allow(lock).to receive(:unlock).and_return(true)
      allow(lock).to receive(:delete).and_return(true)
    end

    it 'raises "HELL"' do
      expect(lock).to receive(:unlock).and_return(true)
      expect(lock).to receive(:delete).and_return(true)

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

  context 'when callback raises error' do
    let(:empty_callback) { -> { raise 'CallbackError' } }

    before do
      allow(lock).to receive(:locked?).and_return(false)
      allow(lock).to receive(:log_warn)
      allow(lock).to receive(:unlock).and_return(true)
      allow(lock).to receive(:delete).and_return(true)
    end

    it 'logs a warning' do
      expect { execute }.to raise_error('CallbackError')
      expect(lock).to have_received(:log_warn).with("the callback for unique_key: #{item['unique_digest']} failed!")
    end
  end
end
