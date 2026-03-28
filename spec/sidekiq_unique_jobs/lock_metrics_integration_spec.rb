# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::LockMetrics, redis_db: 3 do
  let(:middleware_client) { SidekiqUniqueJobs::Middleware::Client.new }
  let(:middleware_server) { SidekiqUniqueJobs::Middleware::Server.new }

  def metrics_for(lock_type, event)
    results = SidekiqUniqueJobs::LockMetrics.query(minutes: 1)
    results["#{lock_type}|#{event}"]
  end

  def total_for(event)
    results = SidekiqUniqueJobs::LockMetrics.query(minutes: 1)
    results["total|#{event}"]
  end

  describe "until_executed" do
    it "records acquired on successful lock" do
      UntilExecutedJob.perform_async("one")

      expect(metrics_for("until_executed", "locked")).to eq(1)
      expect(total_for("locked")).to eq(1)
    end

    it "records denied when lock is already held" do
      UntilExecutedJob.perform_async("one")
      UntilExecutedJob.perform_async("one")

      expect(metrics_for("until_executed", "locked")).to eq(1)
      expect(metrics_for("until_executed", "lock_failed")).to eq(1)
      expect(total_for("lock_failed")).to eq(1)
    end

    it "records released after server execution" do
      jid = UntilExecutedJob.perform_async("one")
      item = Sidekiq::Queue.new("working").find_job(jid).item

      middleware_server.call(UntilExecutedJob.new, item, "working") { true }

      expect(metrics_for("until_executed", "unlocked")).to eq(1)
      expect(total_for("unlocked")).to eq(1)
    end
  end

  describe "until_executing" do
    it "records acquired on successful lock" do
      UntilExecutingJob.perform_async

      expect(metrics_for("until_executing", "locked")).to eq(1)
    end

    it "records denied when lock is already held" do
      UntilExecutingJob.perform_async
      UntilExecutingJob.perform_async

      expect(metrics_for("until_executing", "locked")).to eq(1)
      expect(metrics_for("until_executing", "lock_failed")).to eq(1)
    end

    it "records released when server unlocks before execution" do
      jid = UntilExecutingJob.perform_async
      item = Sidekiq::Queue.new("working").find_job(jid).item

      middleware_server.call(UntilExecutingJob.new, item, "working") { true }

      expect(metrics_for("until_executing", "unlocked")).to eq(1)
    end
  end

  describe "while_executing" do
    it "records acquired when server locks for execution" do
      WhileExecutingJob.perform_async("one")
      jid = Sidekiq::Queue.new("working").entries.first.jid
      item = Sidekiq::Queue.new("working").find_job(jid).item

      middleware_server.call(WhileExecutingJob.new, item, "working") { true }

      expect(metrics_for("while_executing", "locked")).to eq(1)
    end

    it "records released after server execution completes" do
      WhileExecutingJob.perform_async("one")
      jid = Sidekiq::Queue.new("working").entries.first.jid
      item = Sidekiq::Queue.new("working").find_job(jid).item

      middleware_server.call(WhileExecutingJob.new, item, "working") { true }

      expect(metrics_for("while_executing", "unlocked")).to eq(1)
    end
  end

  describe "until_and_while_executing" do
    it "records acquired on client-side lock" do
      UntilAndWhileExecutingJob.perform_async(0)

      expect(metrics_for("until_and_while_executing", "locked")).to eq(1)
    end

    it "records denied when client lock is already held" do
      UntilAndWhileExecutingJob.perform_async(0)
      UntilAndWhileExecutingJob.perform_async(0)

      expect(metrics_for("until_and_while_executing", "locked")).to eq(1)
      expect(metrics_for("until_and_while_executing", "lock_failed")).to eq(1)
    end

    it "records released on server unlock and runtime lock lifecycle" do
      jid = UntilAndWhileExecutingJob.perform_async(0)
      item = Sidekiq::Queue.new("working").find_job(jid).item

      middleware_server.call(UntilAndWhileExecutingJob.new, item, "working") { true }

      # Client lock released + runtime lock released
      expect(metrics_for("until_and_while_executing", "unlocked")).to be >= 1
    end
  end

  describe "until_expired" do
    it "records acquired on successful lock" do
      UntilExpiredJob.perform_async("one")

      expect(metrics_for("until_expired", "locked")).to eq(1)
    end

    it "records denied when lock is already held" do
      UntilExpiredJob.perform_async("one")
      UntilExpiredJob.perform_async("one")

      expect(metrics_for("until_expired", "locked")).to eq(1)
      expect(metrics_for("until_expired", "lock_failed")).to eq(1)
    end
  end

  describe "totals" do
    it "aggregates across lock types" do
      UntilExecutedJob.perform_async("one")
      UntilExecutingJob.perform_async
      UntilExpiredJob.perform_async("one")

      expect(total_for("locked")).to eq(3)
    end
  end
end
