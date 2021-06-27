# frozen_string_literal: true

RSpec.describe MainJob do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "queue" => :customqueue,
        "retry" => true,
        "lock" => :until_executed,
      }
    end
  end
  it_behaves_like "a performing worker" do
    let(:args) { "one" }
  end
end
