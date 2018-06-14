# frozen_string_literal: true

RSpec.describe UniqueOnAllQueuesJob do
  it_behaves_like 'sidekiq with options', options: {
    'retry'                => true,
    'unique'               => :until_executed,
    'unique_on_all_queues' => true,
  }

  it_behaves_like 'a performing worker', args: %w[one two three]
end
