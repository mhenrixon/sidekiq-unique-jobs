# frozen_string_literal: true

RSpec.shared_examples 'an executing lock with error handling' do
  subject(:execute) { lock.execute(&block) }

  let(:block)             { -> {} }
  let(:error_message)     { "the unique_key: #{item['unique_digest']} needs to be unlocked manually" }
  let(:initially_locked?) { true }
  let(:locked?)           { true }

  before do
    allow(lock).to receive(:locked?).and_return(initially_locked?, locked?)
    allow(lock).to receive(:unlock).and_return(true)
    allow(lock).to receive(:delete).and_return(true)
    allow(callback).to receive(:call).and_call_original
    allow(block).to receive(:call).and_call_original
    allow(lock).to receive(:log_warn)
    allow(lock).to receive(:log_fatal)
  end

  context 'when yield fails with other errors' do
    let(:block)   { -> { raise 'HELL' } }
    let(:locked?) { nil }

    it 'raises "HELL"' do
      expect { execute }.to raise_error('HELL')

      expect(lock).to have_received(:unlock)
    end
  end
end
