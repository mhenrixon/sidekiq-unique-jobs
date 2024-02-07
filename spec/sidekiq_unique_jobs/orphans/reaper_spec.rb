# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Orphans::Reaper do
  let(:service)  { redis { |conn| described_class.new(conn) } }
  let(:digest)   { "uniquejobs:digest" }
  let(:job_id)   { "job_id" }
  let(:item)     { raw_item }
  let(:lock)     { SidekiqUniqueJobs::Lock.create(digest, job_id, lock_info: lock_info, score: score) }
  let(:raw_item) { { "class" => MyUniqueJob, "args" => [], "jid" => job_id, "lock_digest" => digest } }

  let(:score) do
    (
      Time.now -
        SidekiqUniqueJobs.config.reaper_timeout -
        SidekiqUniqueJobs::Orphans::RubyReaper::SIDEKIQ_BEAT_PAUSE -
        100
    ).to_f
  end
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

  before do
    # Create the lock key without having a matching digest in a job hash
    #   (this is needed because we want to setup the test conditions manually)
    #   (find this to be more sensible defaults)
    SidekiqUniqueJobs.disable!
    lock
  end

  after do
    SidekiqUniqueJobs.enable!
  end

  describe ".call" do
    subject(:call) { described_class.call(conn) }

    let(:conn) { nil }

    around do |example|
      SidekiqUniqueJobs.use_config(reaper: reaper) do
        example.run
      end
    end

    context "when given a connection" do
      let(:conn)       { instance_spy(ConnectionPool) }
      let(:reaper)     { :ruby }
      let(:reaper_spy) { instance_spy(described_class) }

      before do
        allow(reaper_spy).to receive(:call)
        allow(described_class).to receive(:new).and_return(reaper_spy)
      end

      it "calls the reaper with the given connection" do
        call

        expect(reaper_spy).to have_received(:call)
        expect(described_class).to have_received(:new).with(conn)
      end
    end

    shared_examples "deletes orphans" do
      context "when scheduled" do
        let(:item) { raw_item.merge("at" => Time.now.to_f + 3_600) }

        context "without scheduled job" do
          it "deletes the digest" do
            expect { call }.to change { digests.count }.by(-1)
            expect(unique_keys).to eq([])
          end
        end

        context "with scheduled job" do
          before { push_item(item) }

          it "keeps the digest" do
            expect { call }.not_to change { digests.count }.from(1)
            expect(unique_keys).not_to eq([])
          end
        end
      end

      context "when retried" do
        let(:item) { raw_item.merge("retry_count" => 2, "failed_at" => now_f) }

        context "without job in retry" do
          it "deletes the digest" do
            expect { call }.to change { digests.count }.by(-1)
            expect(unique_keys).to eq([])
          end
        end

        context "with job in retry" do
          before { zadd("retry", Time.now.to_f.to_s, dump_json(item)) }

          it "keeps the digest" do
            expect { call }.not_to change { digests.count }.from(1)
            expect(unique_keys).not_to eq([])
          end
        end
      end

      context "when digest exists in a queue" do
        context "without enqueued job" do
          it "deletes the digest" do
            expect { call }.to change { digests.count }.by(-1)
            expect(unique_keys).to eq([])
          end
        end

        context "with enqueued job" do
          before { push_item(item) }

          it "keeps the digest" do
            expect { call }.not_to change { digests.count }.from(1)
            expect(unique_keys).not_to eq([])
          end
        end
      end

      context "when processing" do
        context "without job in process" do
          it "deletes the digest" do
            expect { call }.to change { digests.count }.by(-1)
            expect(unique_keys).to eq([])
          end
        end

        context "with job in process" do
          let(:process_key)    { "process-id" }
          let(:thread_id)      { "thread-id" }
          let(:worker_key)     { "#{process_key}:work" }
          let(:created_at)     { (Time.now - reaper_timeout).to_f }
          let(:reaper_timeout) { SidekiqUniqueJobs.config.reaper_timeout }

          before do
            SidekiqUniqueJobs.redis do |conn|
              conn.multi do |pipeline|
                if pipeline.respond_to?(:sadd?)
                  pipeline.sadd?("processes", process_key)
                else
                  pipeline.sadd("processes", process_key)
                end
                pipeline.set(process_key, "bogus")
                pipeline.hset(worker_key, thread_id, dump_json(payload: item.merge(created_at: created_at)))
                pipeline.expire(process_key, 60)
                pipeline.expire(worker_key, 60)
              end
            end
          end

          context "when digest has :RUN suffix" do
            let(:lock) { SidekiqUniqueJobs::Lock.create("#{digest}:RUN", job_id, lock_info: lock_info) }

            context "that matches current digest" do # rubocop:disable RSpec/NestedGroups
              let(:created_at) { (Time.now - (reaper_timeout + 100)).to_f }

              it "keeps the digest" do
                expect { call }.not_to change { digests.count }.from(1)
                expect(unique_keys).not_to eq([])
              end
            end
          end

          context "that matches current digest" do
            context "and created_at is old" do # rubocop:disable RSpec/NestedGroups
              let(:created_at) { (Time.now - (reaper_timeout + 100)).to_f }

              it "keeps the digest" do
                expect { call }.not_to change { digests.count }.from(1)
                expect(unique_keys).not_to eq([])
              end
            end

            context "and created_at is recent" do # rubocop:disable RSpec/NestedGroups
              let(:created_at) { Time.now.to_f }

              it "keeps the digest" do
                expect { call }.not_to change { digests.count }.from(1)
                expect(unique_keys).not_to eq([])
              end
            end
          end

          context "that does not match current digest" do
            let(:item) { { "class" => MyUniqueJob, "args" => [], "jid" => job_id, "lock_digest" => "uniquejobs:d2" } }

            context "and created_at is old" do # rubocop:disable RSpec/NestedGroups
              let(:created_at) { (Time.now - (reaper_timeout + 100)).to_f }

              it "deletes the digest" do
                expect { call }.to change { digests.count }.by(-1)
                expect(unique_keys).to eq([])
              end
            end

            context "and created_at is recent" do # rubocop:disable RSpec/NestedGroups
              let(:created_at) { Time.now.to_f }

              it "keeps the digest" do
                expect { call }.not_to change { digests.count }.from(1)
                expect(unique_keys).not_to eq([])
              end
            end
          end
        end
      end
    end

    context "when config.reaper = :ruby" do
      let(:reaper) { :ruby }

      it_behaves_like "deletes orphans"
    end

    context "when config.reaper = :lua" do
      let(:reaper) { :lua }

      it_behaves_like "deletes orphans"
    end

    context "when config.reaper = :bogus" do
      let(:reaper) { :bogus }

      before do
        allow(service).to receive(:log_fatal)
      end

      specify do
        service.call

        expect(service).to have_received(:log_fatal)
          .with(":#{reaper} is invalid for `SidekiqUnqiueJobs.config.reaper`")
      end
    end
  end
end
