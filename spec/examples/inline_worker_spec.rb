# frozen_string_literal: true

RSpec.describe InlineWorker do
  it_behaves_like 'sidekiq with options', options: {
    'lock_timeout' => 5,
    'retry'        => true,
    'unique'       => :while_executing,
  }

  it_behaves_like 'a performing worker', args: 'one'
end
