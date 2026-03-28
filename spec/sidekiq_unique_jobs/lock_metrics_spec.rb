# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::LockMetrics do
  let(:metrics) { described_class.new }
  let(:item) { { "lock" => "until_executed", "class" => "MyJob", "jid" => "abc" } }

  describe "#track" do
    it "accumulates counters in memory" do
      3.times { metrics.track(:locked, item) }
      2.times { metrics.track(:lock_failed, item) }

      # Flush to verify they were tracked
      metrics.flush

      results = described_class.query(minutes: 1)
      expect(results["until_executed|locked"]).to eq(3)
      expect(results["until_executed|lock_failed"]).to eq(2)
      expect(results["total|locked"]).to eq(3)
      expect(results["total|lock_failed"]).to eq(2)
    end
  end

  describe "#flush" do
    it "writes counters to Redis and resets" do
      5.times { metrics.track(:locked, item) }
      metrics.flush

      # Second flush should be empty (counters reset)
      metrics.flush

      results = described_class.query(minutes: 1)
      expect(results["until_executed|locked"]).to eq(5)
    end

    it "does nothing when no events tracked" do
      expect { metrics.flush }.not_to raise_error
    end
  end

  describe ".query" do
    it "returns empty hash when no metrics exist" do
      results = described_class.query(minutes: 1)
      expect(results).to be_empty
    end

    it "aggregates across multiple minute buckets" do
      # Flush at different times
      metrics.track(:locked, item)
      metrics.flush(Time.now)

      metrics.track(:locked, item)
      metrics.track(:locked, item)
      metrics.flush(Time.now - 30) # 30 seconds ago, same minute bucket

      results = described_class.query(minutes: 2)
      expect(results["until_executed|locked"]).to eq(3)
    end
  end

  describe ".by_type" do
    before do
      metrics.track(:locked, { "lock" => "until_executed" })
      metrics.track(:locked, { "lock" => "until_executed" })
      metrics.track(:lock_failed, { "lock" => "until_executed" })
      metrics.track(:locked, { "lock" => "while_executing" })
      metrics.flush
    end

    it "groups by lock type" do
      results = described_class.by_type(minutes: 1)
      types = results.to_h

      expect(types["until_executed"][:locked]).to eq(2)
      expect(types["until_executed"][:lock_failed]).to eq(1)
      expect(types["while_executing"][:locked]).to eq(1)
      expect(types["total"][:locked]).to eq(3)
    end

    it "sorts total last" do
      results = described_class.by_type(minutes: 1)
      expect(results.last.first).to eq("total")
    end
  end
end
