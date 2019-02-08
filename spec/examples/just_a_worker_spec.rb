# frozen_string_literal: true
require "spec_helper"
RSpec.describe JustAWorker do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "queue" => :testqueue,
        "retry" => true,
        "lock" => :until_executed,
      }
    end
  end
  it_behaves_like "a performing worker" do
    let(:args) { { "test" => 1 } }
  end
end
