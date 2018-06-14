# frozen_string_literal: true

RSpec.describe MyUniqueJob do
  it_behaves_like 'sidekiq with options', options: {
    'queue'           => :customqueue,
    'retry'           => true,
    'retry_count'     => 10,
    'lock_expiration' => 7_200,
    'unique'          => :until_executed,
  }

  it_behaves_like 'a performing worker', args: %w[one two]
end
