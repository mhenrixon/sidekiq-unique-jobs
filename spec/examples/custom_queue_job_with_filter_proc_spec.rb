# frozen_string_literal: true

RSpec.describe CustomQueueJobWithFilterProc do
  it_behaves_like 'sidekiq with options', options: {
    'queue'       => :customqueue,
    'retry'       => true,
    'unique'      => :until_timeout,
    # 'unique_args' => a_kind_of(Proc)
  }

  it_behaves_like 'a performing worker',
                  args: [1, { 'random' => rand, 'name' => 'foobar' }],
                  splat: false
end
