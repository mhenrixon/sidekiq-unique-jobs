# frozen_string_literal: true

RSpec.describe SimpleWorker do
  it_behaves_like 'sidekiq with options', options: {
    'queue'       => :default,
    'retry'       => true,
    'unique'      => :until_executed,
  }

  it_behaves_like 'a performing worker',
                  args: [
                    'one',
                    { 'type' => 'unique', 'id' => 2 },
                  ],
                  splat: false

  describe 'unique_args' do
    subject do
      described_class.get_sidekiq_options['unique_args'].call(args)
    end

    let(:args) do
      [
        'unique',
        { 'type' => 'unique', 'id' => 2 },
      ]
    end

    it { is_expected.to eq(['unique']) }
  end
end
