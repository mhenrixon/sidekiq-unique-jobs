# frozen_string_literal: true

RSpec.describe UniqueJobOnConflictReplace, :perf do
  let(:lock_prefix)  { SidekiqUniqueJobs.config.lock_prefix }
  let(:lock_timeout) { SidekiqUniqueJobs.config.lock_timeout }
  let(:lock_ttl)     { SidekiqUniqueJobs.config.lock_ttl }
  let(:queue)        { described_class.sidekiq_options["queue"] }
  let(:on_conflict)  { described_class.sidekiq_options["on_conflict"] }
  let(:lock)         { described_class.sidekiq_options["lock"] }

  before do
    digests.delete_by_pattern("*")
  end

  context "when schedule queue is large" do
    it "locks and replaces quickly" do
      (0..100_000).each_slice(1_000) do |nums|
        redis do |conn|
          conn.pipelined do |pipeline|
            nums.each do |num|
              created_at   = Time.now.to_f
              scheduled_at = created_at + rand(3_600..2_592_000)

              payload = {
                "retry" => true,
                "queue" => queue,
                "lock" => lock,
                "on_conflict" => on_conflict,
                "class" => described_class.name,
                "args" => [num, { "type" => "extremely unique" }],
                "jid" => SecureRandom.hex(12),
                "created_at" => created_at,
                "lock_timeout" => lock_timeout,
                "lock_ttl" => lock_ttl,
                "lock_prefix" => lock_prefix,
                "lock_args" => [num, { "type" => "extremely unique" }],
                "lock_digest" => "#{lock_prefix}:#{SecureRandom.hex}",
              }

              pipeline.zadd("schedule", scheduled_at, payload.to_json)
            end
          end
        end
      end

      # queueing it once at the end of the queue should succeed
      expect(described_class.perform_in(2_592_000, 100_000, { "type" => "extremely unique" })).not_to be_nil

      # queueing it again should be performant
      expect do
        Timeout.timeout(0.1) do
          described_class.perform_in(2_592_000, 100_000, { "type" => "extremely unique" })
        end
      end.not_to raise_error
    end
  end
end
