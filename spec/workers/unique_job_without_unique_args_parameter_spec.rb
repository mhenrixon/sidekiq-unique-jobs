# frozen_string_literal: true

RSpec.describe UniqueJobWithoutUniqueArgsParameter do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "backtrace" => true,
        "queue" => :customqueue,
        "retry" => true,
        "lock" => :until_executed,
        "lock_args_method" => :unique_args,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { true }
  end
end
