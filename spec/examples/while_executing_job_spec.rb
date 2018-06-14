# frozen_string_literal: true

RSpec.describe WhileExecutingJob do
  it_behaves_like 'sidekiq with options', options: {
    'backtrace' => 10,
    'queue'     => :working,
    'retry'     => 1,
    'unique'    => :while_executing,
  }

  it_behaves_like 'a performing worker', args: ['one']
end
