# frozen_string_literal: true

require "spec_helper"
RSpec.describe UniqueOnAllQueuesJob do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "retry" => true,
        "lock" => :until_executed,
        "unique_across_queues" => true,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { %w[one two three] }
  end
end
