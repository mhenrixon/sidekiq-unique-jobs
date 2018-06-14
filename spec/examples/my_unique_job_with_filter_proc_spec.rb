# frozen_string_literal: true

RSpec.describe MyUniqueJobWithFilterProc do
  it_behaves_like 'sidekiq with options', options: {
    'backtrace'   => true,
    'queue'       => :customqueue,
    'retry'       => true,
    'unique'      => :until_executed,
  }

  it_behaves_like 'a performing worker',
                  args: [
                    'one',
                    { 'type' => 'unique', 'id' => 2 },
                  ]

  describe 'unique_args' do
    subject do
      described_class.get_sidekiq_options['unique_args'].call(args)
    end

    let(:args) do
      [
        'one',
        { 'type' => 'unique', 'id' => 2 },
      ]
    end

    it { is_expected.to eq(%w[one unique]) }
  end
end
