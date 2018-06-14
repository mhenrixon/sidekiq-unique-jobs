# frozen_string_literal: true

RSpec.describe CustomQueueJobWithFilterMethod do
  it_behaves_like 'sidekiq with options', options: {
    'queue'       => :customqueue,
    'retry'       => true,
    'unique'      => :until_executed,
    'unique_args' => :args_filter,
  }

  it_behaves_like 'a performing worker', args: %w[one two]
end
