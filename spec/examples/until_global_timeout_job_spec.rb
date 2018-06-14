# frozen_string_literal: true

RSpec.describe UntilGlobalTimeoutJob do
  it_behaves_like 'sidekiq with options', options: {
    'retry'  => true,
    'unique' => :until_timeout,
  }

  it_behaves_like 'a performing worker', args: ['one']
end
