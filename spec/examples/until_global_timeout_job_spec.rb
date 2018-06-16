# frozen_string_literal: true

RSpec.describe UntilGlobalTimeoutJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'retry'  => true,
        'unique' => :until_timeout,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { 'one' }
  end
end
