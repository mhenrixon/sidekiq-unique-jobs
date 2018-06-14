# frozen_string_literal: true

RSpec.describe MyUniqueJobWithFilterMethod do
  it_behaves_like 'sidekiq with options', options: {
    'backtrace'   => true,
    'queue'       => :customqueue,
    'retry'       => true,
    'unique'      => :until_executed,
    'unique_args' => :filtered_args,
  }

  it_behaves_like 'a performing worker',
                  args: [
                    'hundred',
                    { 'type' => 'extremely unique', 'id' => 44 },
                  ]
  describe '.filtered_args' do
    subject do
      described_class.filtered_args(args)
    end

    let(:args) do
      [
        'two',
        { 'type' => 'very unique', 'id' => 4 },
      ]
    end

    it { is_expected.to eq(['two', 'very unique']) }
  end
end
