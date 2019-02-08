# frozen_string_literal: true
require "spec_helper"
RSpec.describe UniqueAcrossWorkersJob do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "retry" => true,
        "lock" => :until_executed,
        "unique_across_workers" => true,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { %w[one two] }
  end
end
