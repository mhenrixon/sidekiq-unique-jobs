# frozen_string_literal: true

RSpec.describe NotifyWorker do
  it_behaves_like 'sidekiq with options', options: {
    'queue'           => :notify_worker,
    'retry'           => true,
    'unique'          => :until_executed,
  }

  it_behaves_like 'a performing worker', args: %w[one two]
end
