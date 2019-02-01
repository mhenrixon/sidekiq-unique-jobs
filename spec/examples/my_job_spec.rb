# frozen_string_literal: true

require "spec_helper"

RSpec.describe MyJob do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "backtrace" => 10,
        "queue" => :working,
        "retry" => 1,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { "one" }
  end
end
