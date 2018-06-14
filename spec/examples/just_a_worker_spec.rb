# frozen_string_literal: true

RSpec.describe JustAWorker do
  it_behaves_like 'sidekiq with options', options: {
    'queue'  => :testqueue,
    'retry'  => true,
    'unique' => :until_executed,
  }

  it_behaves_like 'a performing worker', args: { 'test' => 1 }, splat: false
end
