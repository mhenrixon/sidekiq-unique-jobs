# frozen_string_literal: true

RSpec.describe UniqueJobWithoutUniqueArgsParameter do
  it_behaves_like 'sidekiq with options', options: {
    'backtrace'   => true,
    'queue'       => :customqueue,
    'retry'       => true,
    'unique'      => :until_executed,
    'unique_args' => :unique_args,
  }

  it_behaves_like 'a performing worker', args: [true]
end
