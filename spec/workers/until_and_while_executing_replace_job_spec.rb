# frozen_string_literal: true

RSpec.describe UntilAndWhileExecutingReplaceJob do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "queue" => :working,
        "retry" => true,
        "lock" => :until_and_while_executing,
        "on_conflict" => { client: :replace, server: :reschedule },
      }
    end
  end

  it "replaces the previous job successfully" do
    Sidekiq::Testing.disable! do
      set = Sidekiq::ScheduledSet.new

      described_class.perform_at(Time.now + 30, "unique", "first argument")
      expect(set.size).to eq(1)
      expect(set.first.item["args"]).to eq(["unique", "first argument"])

      described_class.perform_at(Time.now + 30, "unique", "new argument")
      expect(set.size).to eq(1)
      expect(set.first.item["args"]).to eq(["unique", "new argument"])

      set.each(&:delete)
    end
  end

  it "replaces the previous job successfully when using perform_in" do
    Sidekiq::Testing.disable! do
      set = Sidekiq::ScheduledSet.new

      described_class.perform_in(30, "unique", "first argument")
      expect(set.size).to eq(1)
      expect(set.first.item["args"]).to eq(["unique", "first argument"])

      described_class.perform_in(30, "unique", "new argument")
      expect(set.size).to eq(1)
      expect(set.first.item["args"]).to eq(["unique", "new argument"])

      set.each(&:delete)
    end
  end
end
