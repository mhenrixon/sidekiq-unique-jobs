# frozen_string_literal: true

RSpec.describe UntilExecutingJob do
  it_behaves_like 'sidekiq with options', options: {
    'queue'  => :working,
    'retry'  => true,
    'unique' => :until_executing,
  }

  it_behaves_like 'a performing worker', args: nil
end
