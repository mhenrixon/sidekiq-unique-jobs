# frozen_string_literal: true

RSpec.describe WhileExecutingJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'backtrace' => 10,
        'queue'     => :working,
        'retry'     => 1,
        'unique'    => :while_executing,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) {'one' }
  end
end
