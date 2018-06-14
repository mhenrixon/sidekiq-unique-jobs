# frozen_string_literal: true

RSpec.describe WithoutArgumentJob do
  it_behaves_like 'sidekiq with options', options: {
    'log_duplicate_payload' => true,
    'retry'                 => true,
    'unique'                => :until_executed,
  }

  it_behaves_like 'a performing worker', args: nil
end
