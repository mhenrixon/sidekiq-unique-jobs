# frozen_string_literal: true

RSpec.describe LongRunningRunLockExpirationJob do
  it_behaves_like 'sidekiq with options', options: {
    'queue'               => :customqueue,
    'retry'               => true,
    'retry_count'         => 10,
    'run_lock_expiration' => 3_600,
    'unique'              => :until_and_while_executing,
  }

  it_behaves_like 'a performing worker', args: %w[one two]
end
