# frozen_string_literal: true

RSpec.describe SpawnSimpleWorker do
  it_behaves_like 'sidekiq with options', options: {
    'queue'       => :not_default,
    'retry'       => true,
  }

  it_behaves_like 'a performing worker',
                  args: [
                    'one',
                    { 'type' => 'unique', 'id' => 2 },
                  ],
                  splat: false

  describe '#perform' do
    let(:args) { %w[one two] }

    it 'spawns another job' do
      expect(SimpleWorker).to receive(:perform_async).with(args).and_return(true)
      subject.perform(args)
    end
  end
end
