# frozen_string_literal: true

RSpec.describe LongRunningJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'queue'           => :customqueue,
        'retry'           => true,
        'unique'          => :until_and_while_executing,
        'lock_expiration' => 7_200,
        'retry_count'     => 10,
      }
    end
  end
  it_behaves_like 'a performing worker' do
    let(:args) { %w[one two] }
  end
end
