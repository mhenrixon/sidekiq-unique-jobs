# frozen_string_literal: true

RSpec.describe CustomQueueJob do
  it_behaves_like 'sidekiq with options', options: {
    'queue' => :customqueue,
    'retry' => true,
  }

  it_behaves_like 'a performing worker', args: %w[one two]
end
