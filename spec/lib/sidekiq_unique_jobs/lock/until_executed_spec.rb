require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilExecuted do
  describe '#execute' do
    subject { described_class.new(item) }
    let(:item) do
      { 'jid' => 'maaaahjid', 'class' => 'UntilExecutedJob', 'unique' => 'until_executed' }
    end
    let(:empty_callback) { -> {} }

    def execute
      subject.execute(empty_callback)
    end

    context 'when yield fails with Sidekiq::Shutdown' do
      before do
        allow(subject).to receive(:after_yield_yield) { fail Sidekiq::Shutdown }
      end

      it 'raises Sidekiq::Shutdown' do
        allow(subject).to receive(:unlock).and_return(true)
        expect(subject).not_to receive(:unlock)
        expect(empty_callback).not_to receive(:call)
        expect { subject.execute(empty_callback) }.to raise_error(Sidekiq::Shutdown)
      end
    end

    context 'when yield fails with other errors' do
      before do
        allow(subject).to receive(:after_yield_yield) { fail 'Hell' }
      end

      it 'raises Sidekiq::Shutdown' do
        expect(subject).to receive(:unlock).and_return(true)
        expect(empty_callback).to receive(:call)
        expect { subject.execute(empty_callback) }.to raise_error('Hell')
      end
    end
  end
end
