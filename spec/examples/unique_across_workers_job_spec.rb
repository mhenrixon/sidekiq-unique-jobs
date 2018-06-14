# frozen_string_literal: true

RSpec.describe UniqueAcrossWorkersJob do
  it_behaves_like 'sidekiq with options', options: {
    'retry'                 => true,
    'unique'                => :until_executed,
    'unique_across_workers' => true,
  }

  it_behaves_like 'a performing worker', args: %w[one two]
end
