# frozen_string_literal: true

RSpec.describe "reap_orphans.lua" do
  subject(:reap_orphans) do
    call_script(
      :reap_orphans,
      keys: redis_keys,
      argv: argv,
    )
  end

  let(:redis_keys) do
    [
      SidekiqUniqueJobs::DIGESTS,
      SidekiqUniqueJobs::EXPIRING_DIGESTS,
      SidekiqUniqueJobs::SCHEDULE,
      SidekiqUniqueJobs::RETRY,
    ]
  end
  let(:argv)       { [100, threshold] }
  let(:digest)     { "uniquejobs:digest" }
  let(:lock)       { SidekiqUniqueJobs::Lock.create(digest, job_id, lock_info) }
  let(:job_id)     { "job_id" }
  let(:item)       { raw_item }
  let(:created_at) { (Time.now - 1000).to_f }
  let(:threshold)  { [Time.now - SidekiqUniqueJobs.config.reaper_timeout] }
  let(:raw_item) do
    {
      "class" => MyUniqueJob,
      "args" => [1, 2],
      "jid" => job_id,
      "lock_digest" => digest,
      "created_at" => created_at,
    }
  end
  let(:lock_info) do
    {
      "job_id" => job_id,
      "limit" => 1,
      "lock" => :while_executing,
      "time" => now_f,
      "timeout" => nil,
      "ttl" => nil,
      "lock_args" => [1, 2],
      "worker" => "MyUniqueJob",
    }
  end

  before do
    SidekiqUniqueJobs.disable!
    lock
  end

  after do
    SidekiqUniqueJobs.enable!
  end

  context "when scheduled" do
    let(:item) { raw_item.merge("at" => Time.now.to_f + 3_600) }

    context "without scheduled job" do
      it "keeps the digest" do
        expect { reap_orphans }.to change { digests.count }.by(-1)
        expect(unique_keys).to be_empty
      end
    end

    context "with scheduled job" do
      before { push_item(item) }

      it "keeps the digest" do
        expect { reap_orphans }.not_to change { digests.count }.from(1)
        expect(unique_keys).not_to be_empty
      end
    end
  end

  context "when retried" do
    let(:item) { raw_item.merge("retry_count" => 2, "failed_at" => now_f) }

    context "without job in retry" do
      it "keeps the digest" do
        expect { reap_orphans }.to change { digests.count }.by(-1)
        expect(unique_keys).to be_empty
      end
    end

    context "with job in retry" do
      before { zadd("retry", Time.now.to_f.to_s, dump_json(item)) }

      it "keeps the digest" do
        expect { reap_orphans }.not_to change { digests.count }.from(1)
        expect(unique_keys).not_to be_empty
      end
    end
  end

  context "when digest exists in a queue" do
    context "without enqueued job" do
      it "keeps the digest" do
        expect { reap_orphans }.to change { digests.count }.by(-1)
        expect(unique_keys).to be_empty
      end
    end

    context "with enqueued job" do
      before { push_item(item) }

      it "keeps the digest" do
        expect { reap_orphans }.not_to change { digests.count }.from(1)
        expect(unique_keys).not_to be_empty
      end
    end
  end

  context "when digest exists in a a process set" do
    context "without job" do
      it "keeps the digest" do
        expect { reap_orphans }.to change { digests.count }.by(-1)
        expect(unique_keys).to be_empty
      end
    end

    context "with job" do
      let(:process_key) { "process-id" }
      let(:thread_id)   { "thread-id" }
      let(:worker_key)  { "#{process_key}:work" }

      before do
        SidekiqUniqueJobs.redis do |conn|
          conn.multi do |pipeline|
            if pipeline.respond_to?(:sadd?)
              pipeline.sadd?("processes", process_key)
            else
              pipeline.sadd("processes", process_key)
            end
            pipeline.hset(worker_key, thread_id, dump_json(item))
            pipeline.expire(process_key, 60)
            pipeline.expire(worker_key, 60)
          end
        end
      end

      it "keeps the digest" do
        expect { reap_orphans }.not_to change { digests.count }.from(1)
        expect(unique_keys).not_to be_empty
      end
    end
  end
end
