# frozen_string_literal: true

RSpec.describe MainJob do
  it_behaves_like 'sidekiq with options', options: {
    'log_duplicate_payload' => true,
    'queue'               => :customqueue,
    'retry'               => true,
    'unique'              => :until_executed,
  }

  it_behaves_like 'a performing worker', args: 'one'
end
