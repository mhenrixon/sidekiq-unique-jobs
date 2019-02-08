# frozen_string_literal: true

RSpec.describe UniqueOnAllQueuesJob do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "retry" => true,
        "lock" => :until_executed,
        "unique_on_all_queues" => true,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { %w[one two three] }
  end
end
