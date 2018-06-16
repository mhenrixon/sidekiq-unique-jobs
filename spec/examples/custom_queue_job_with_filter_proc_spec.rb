# frozen_string_literal: true

RSpec.describe CustomQueueJobWithFilterProc do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'queue'       => :customqueue,
        'retry'       => true,
        'unique'      => :until_timeout,
        'unique_args' => a_kind_of(Proc),
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { [1, 'random' => rand, 'name' => 'foobar'] }
  end
end
