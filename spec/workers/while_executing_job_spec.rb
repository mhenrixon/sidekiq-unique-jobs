# frozen_string_literal: true

RSpec.describe WhileExecutingJob do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "backtrace" => 10,
        "queue" => :working,
        "retry" => 1,
        "lock" => :while_executing,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { "one" }
  end

  describe "client middleware" do
    context "when job is already scheduled" do
      it "pushes the job immediately" do
        described_class.perform_in(3600, 1)
        expect(described_class.perform_async(1)).not_to be_nil
      end
    end
  end
end
