# frozen_string_literal: true
require "spec_helper"
RSpec.describe UntilGlobalExpiredJob do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "retry" => true,
        "lock" => :until_expired,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { "one" }
  end
end
