# frozen_string_literal: true

RSpec.describe LongRunningRunLockExpirationJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'queue'               => :customqueue,
        'retry'               => true,
        'retry_count'         => 10,
        'run_lock_expiration' => 3_600,
        'unique'              => :until_and_while_executing,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { %w[one two] }
  end
end
