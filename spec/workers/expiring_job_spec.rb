# frozen_string_literal: true

RSpec.describe ExpiringJob do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "lock_ttl" => 600,
        "retry" => true,
        "lock" => :until_executed,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { [1, 2] }
  end

  describe "client middleware" do
    context "when job is delayed" do
      before { described_class.perform_in(60, 1, 2) }

      it "rejects new scheduled jobs" do
        expect(1).to be_enqueued_in("customqueue")
        described_class.perform_in(3600, 1, 2)
        expect(1).to be_enqueued_in("customqueue")
        expect(1).to be_scheduled_at(Time.now.to_f + (2 * 60))
      end

      it "rejects new jobs" do
        described_class.perform_async(1, 2)
        expect(1).to be_enqueued_in("customqueue")
      end

      it "allows duplicate messages to different queues" do
        expect(1).to be_enqueued_in("customqueue2")
        described_class.use_options(queue: "customqueue2") do
          described_class.perform_async(1, 2)
          expect(1).to be_enqueued_in("customqueue2")
        end
      end
    end

    context "when job is pushed" do
      before { described_class.perform_async(1, 2) }

      it "rejects new scheduled jobs" do
        expect(1).to be_enqueued_in("customqueue")
        described_class.perform_in(60, 1, 2)
        expect(1).to be_enqueued_in("customqueue")
        expect(0).to be_scheduled_at(Time.now.to_f + (2 * 60))
      end

      it "rejects new jobs" do
        expect(1).to be_enqueued_in("customqueue")
        described_class.perform_async(1, 2)
        expect(1).to be_enqueued_in("customqueue")
      end

      it "allows duplicate messages to different queues" do
        expect(1).to be_enqueued_in("customqueue")
        expect(0).to be_enqueued_in("customqueue2")
        described_class.use_options(queue: "customqueue2") do
          described_class.perform_async(1, 2)
          expect(1).to be_enqueued_in("customqueue2")
        end
      end
    end
  end
end
