# frozen_string_literal: true

RSpec.describe MyJob do
  it_behaves_like 'sidekiq with options', options: {
    'backtrace' => 10,
    'queue'     => :working,
    'retry'     => 1,
  }

  it_behaves_like 'a performing worker', args: 'one'
end
