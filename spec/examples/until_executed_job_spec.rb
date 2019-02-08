# frozen_string_literal: true
require "spec_helper"
RSpec.describe UntilExecutedJob do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "backtrace" => 10,
        "lock_timeout" => 0,
        "lock_expiration" => 5000,
        "queue" => :working,
        "retry" => 1,
        "lock" => :until_executed,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { %w[one two] }
  end
end
