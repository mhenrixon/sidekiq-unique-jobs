# frozen_string_literal: true

require "spec_helper"

RSpec.describe UntilExecuted2Job do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "backtrace" => 10,
        "lock" => :until_executed,
        "lock_timeout" => 0,
        "queue" => :working,
        "retry" => 1,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { %w[one two] }
  end
end
