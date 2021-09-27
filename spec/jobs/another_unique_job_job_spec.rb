# frozen_string_literal: true

if Sidekiq.const_defined?("JobRecord")
  RSpec.describe AnotherUniqueJobJob do
    it_behaves_like "sidekiq with options" do
      let(:options) do
        {
          "queue" => :working2,
          "retry" => 1,
          "backtrace" => 10,
          "lock" => :until_executed,
        }
      end
    end

    it_behaves_like "a performing worker", splat_arguments: false do
      let(:args) { %w[one two] }
    end
  end
end
