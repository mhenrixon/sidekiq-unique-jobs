# frozen_string_literal: true

RSpec.describe MyUniqueJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'queue'           => :customqueue,
        'retry'           => true,
        'retry_count'     => 10,
        'lock_expiration' => 7_200,
        'unique'          => :until_executed,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { %w[one two] }
  end

  describe 'client middleware' do
    context 'when job is already scheduled' do
      before { described_class.perform_in(3600, 1, 2) }

      it 'rejects new scheduled jobs' do
        expect(described_class.perform_in(3600, 1, 2)).to eq(nil)
        expect(1).to be_enqueued_in('customqueue')
      end

      it 'rejects new jobs' do
        expect(described_class.perform_async(1, 2)).to eq(nil)
        expect(1).to be_enqueued_in('customqueue')
      end

      it 'allows duplicate messages to different queues' do
        expect(described_class.set(queue: 'customqueue2').perform_async(1, 2)).not_to eq(nil)
        expect(1).to be_enqueued_in('customqueue2')
      end
    end
  end
end
