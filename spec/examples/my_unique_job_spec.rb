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
end
