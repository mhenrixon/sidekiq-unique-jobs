# frozen_string_literal: true

RSpec.describe ExpiringJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'lock_expiration' => 600,
        'retry'           => true,
        'unique'          => :until_executed,
      }
    end
  end
  it_behaves_like 'a performing worker' do
    let(:args) { [1, 2] }
  end
end
