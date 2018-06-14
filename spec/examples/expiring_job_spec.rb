# frozen_string_literal: true

RSpec.describe ExpiringJob do
  it_behaves_like 'sidekiq with options', options: {
    'lock_expiration' => 600,
    'retry'           => true,
    'unique'          => :until_executed,
  }

  it_behaves_like 'a performing worker',
                  args: [1, 2]
end
