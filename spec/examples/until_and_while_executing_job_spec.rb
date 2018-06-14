# frozen_string_literal: true

RSpec.describe UntilAndWhileExecutingJob do
  it_behaves_like 'sidekiq with options', options: {
    'queue'  => :working,
    'retry'  => true,
    'unique' => :until_and_while_executing,
  }

  it_behaves_like 'a performing worker', args: [%w[one]]
end
