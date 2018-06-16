# frozen_string_literal: true

RSpec.describe SpawnSimpleWorker do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'queue'       => :not_default,
        'retry'       => true,
      }
    end
  end

  it_behaves_like 'a performing worker', splat_arguments: false do
    let(:args) { ['one', 'type' => 'unique', 'id' => 2] }
  end

  describe '#perform' do
    let(:args) { %w[one two] }

    it 'spawns another job' do
      expect(SimpleWorker).to receive(:perform_async).with(args).and_return(true)
      described_class.new.perform(args)
    end
  end
end
