# frozen_string_literal: true

require "spec_helper"
RSpec.describe UniqueJobWithoutUniqueArgsParameter do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "backtrace" => true,
        "queue" => :customqueue,
        "retry" => true,
        "lock" => :until_executed,
        "unique_args" => :unique_args,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { true }
  end
end
