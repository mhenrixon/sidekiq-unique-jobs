# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Orphans::RubyReaper do
  let(:service)  { redis { |conn| described_class.new(conn) } }
  let(:digest)   { "uniquejobs:digest" }
  let(:job_id)   { "job_id" }
  let(:item)     { raw_item }
  let(:lock)     { SidekiqUniqueJobs::Lock.create(digest, job_id, lock_info) }
  let(:raw_item) { { "class" => MyUniqueJob, "args" => [], "jid" => job_id, "lock_digest" => digest } }
  let(:lock_info) do
    {
      "job_id" => job_id,
      "limit" => 1,
      "lock" => :while_executing,
      "time" => now_f,
      "timeout" => nil,
      "ttl" => nil,
      "lock_args" => [],
      "worker" => "MyUniqueJob",
    }
  end

  describe "#in_sorted_set?" do
    subject(:in_sorted_set?) { service.send(:in_sorted_set?, "retry", digest) }

    context "when retried" do
      let(:item) { raw_item.merge("retry_count" => 2, "failed_at" => now_f) }

      context "with job in retry", perf: true do
        before do
          puts "#{Time.now} - Adding 100_000 to retry queue"

          1_000_000.times do |i|
            zadd("retry", (Time.now.to_f - i).to_s, dump_json(item.except("lock_digest")))
          end

          zadd("retry", (Time.now.to_f + 200_000).to_s, dump_json(item))

          puts "#{Time.now} - Done adding to retry queue"
        end

        it { expect { service.send(:in_sorted_set?, "retry", digest) }.to perform_under(2).ms }
      end
    end
  end
end
