# frozen_string_literal: true

RSpec.describe UntilTimeoutJob do
  it_behaves_like 'sidekiq with options', options: {
    'lock_expiration' => 600,
    'lock_timeout'    => 10,
    'retry'           => true,
    'unique'          => :until_timeout,
  }

  it_behaves_like 'a performing worker', args: ['one']
end
