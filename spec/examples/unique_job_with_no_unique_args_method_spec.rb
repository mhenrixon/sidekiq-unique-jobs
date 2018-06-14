# frozen_string_literal: true

RSpec.describe UniqueJobWithNoUniqueArgsMethod do
  it_behaves_like 'sidekiq with options', options: {
    'backtrace'   => true,
    'queue'       => :customqueue,
    'retry'       => true,
    'unique'      => :until_executed,
    'unique_args' => :filtered_args,
  }

  it_behaves_like 'a performing worker', args: %w[one two]
end
