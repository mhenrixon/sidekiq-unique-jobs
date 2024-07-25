# frozen_string_literal: true

RSpec.describe UntilAndWhileExecutingRejectJob do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "lock" => :until_and_while_executing,
        "on_conflict" => { "client" => :reject, "server" => :reject },
        "queue" => :working,
        "retry" => true,
      }
    end
  end

  it "rejects the job successfully" do
    Sidekiq::Testing.disable! do
      set = Sidekiq::ScheduledSet.new

      described_class.perform_at(Time.now + 30, 1)
      expect(set.size).to eq(1)

      expect(described_class.perform_at(Time.now + 30, 1)).to be_nil

      set.each(&:delete)
    end
  end

  it "rejects job successfully when using perform_in" do
    Sidekiq::Testing.disable! do
      set = Sidekiq::ScheduledSet.new

      described_class.perform_in(30, 1)
      expect(set.size).to eq(1)

      expect(described_class.perform_in(30, 1)).to be_nil

      set.each(&:delete)
    end
  end
end
