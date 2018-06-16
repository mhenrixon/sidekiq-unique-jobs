# frozen_string_literal: true

RSpec.describe WithoutArgumentJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'log_duplicate_payload' => true,
        'retry'                 => true,
        'unique'                => :until_executed,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { no_args }
  end
end
