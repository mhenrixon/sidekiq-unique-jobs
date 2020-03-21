# frozen_string_literal: true

RSpec.describe UntilAndWhileExecutingJob do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "queue" => :working,
        "retry" => true,
        "lock" => :until_and_while_executing,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { [%w[one]] }
  end
end
