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
    context 'when job is delayed' do
      before { described_class.perform_in(3600, 1, 2) }

      it 'rejects new scheduled jobs' do
        expect(1).to be_enqueued_in('customqueue')
        described_class.perform_in(3600, 1, 2)
        expect(1).to be_enqueued_in('customqueue')
        expect(1).to be_scheduled_at(Time.now.to_f + 2 * 3600)
      end

      it 'rejects new jobs' do
        described_class.perform_async(1, 2)
        expect(1).to be_enqueued_in('customqueue')
      end

      it 'allows duplicate messages to different queues' do
        expect(1).to be_enqueued_in('customqueue2')
        described_class.set(queue: 'customqueue2').perform_async(1, 2)
        expect(1).to be_enqueued_in('customqueue2')
      end
    end

    context 'when job is pushed' do
      before { described_class.perform_async(1, 2) }

      it 'rejects new scheduled jobs' do
        expect(1).to be_enqueued_in('customqueue')
        described_class.perform_in(60, 1, 2)
        expect(1).to be_enqueued_in('customqueue')
        expect(0).to be_scheduled_at(Time.now.to_f + 2 * 60)
      end

      it 'rejects new jobs' do
        expect(1).to be_enqueued_in('customqueue')
        described_class.perform_async(1, 2)
        expect(1).to be_enqueued_in('customqueue')
      end

      it 'allows duplicate messages to different queues' do
        expect(1).to be_enqueued_in('customqueue')
        expect(0).to be_enqueued_in('customqueue2')

        described_class.set(queue: 'customqueue2').perform_async(1, 2)

        expect(1).to be_enqueued_in('customqueue2')
      end
    end
  end
end
