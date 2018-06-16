# frozen_string_literal: true

RSpec.describe WhileExecutingJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'backtrace' => 10,
        'queue'     => :working,
        'retry'     => 1,
        'unique'    => :while_executing,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { 'one' }
  end

  context 'when job is already scheduled' do
    let(:args) { 1 }

    it 'pushes the job immediately' do
      described_class.perform_in(3600, args)
      expect(described_class.perform_async(args)).not_to eq(nil)
    end
  end
end
