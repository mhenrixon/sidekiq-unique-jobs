# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Orphans::Reaper do
  let(:digest)   { "uniquejobs:reaper-test" }
  let(:job_id)   { "reaper-test-jid" }
  let(:digests)  { SidekiqUniqueJobs::Digests.new }

  describe ".call" do
    subject(:call) { described_class.call }

    around do |example|
      SidekiqUniqueJobs.use_config(reaper: reaper) do
        example.run
      end
    end

    # v9 reaper: checks if LOCKED hash exists.
    # If LOCKED is gone, removes the stale ZSET entry.
    # If LOCKED exists, keeps the ZSET entry.
    shared_examples "v9 reaper behavior" do
      context "when LOCKED hash still exists" do
        before do
          redis do |conn|
            conn.call("HSET", "#{digest}:LOCKED", job_id, Time.now.to_f.to_s)
            conn.call("ZADD", "uniquejobs:digests", Time.now.to_f.to_s, digest)
          end
        end

        it "keeps the digest" do
          expect { call }.not_to change { digests.count }
        end
      end

      context "when LOCKED hash is gone (TTL expired)" do
        before do
          redis do |conn|
            # Stale ZSET entry with no corresponding LOCKED hash
            conn.call("ZADD", "uniquejobs:digests", Time.now.to_f.to_s, digest)
          end
        end

        it "removes the stale digest entry" do
          expect { call }.to change { digests.count }.by(-1)
        end
      end

      context "when multiple digests, some stale" do
        let(:alive_digest) { "uniquejobs:alive" }
        let(:stale_digest) { "uniquejobs:stale" }

        before do
          redis do |conn|
            # Alive: has LOCKED hash
            conn.call("HSET", "#{alive_digest}:LOCKED", "alive-jid", Time.now.to_f.to_s)
            conn.call("ZADD", "uniquejobs:digests", Time.now.to_f.to_s, alive_digest)

            # Stale: no LOCKED hash
            conn.call("ZADD", "uniquejobs:digests", Time.now.to_f.to_s, stale_digest)
          end
        end

        it "only removes the stale one" do
          expect { call }.to change { digests.count }.by(-1)

          redis do |conn|
            expect(conn.call("ZSCORE", "uniquejobs:digests", alive_digest)).not_to be_nil
            expect(conn.call("ZSCORE", "uniquejobs:digests", stale_digest)).to be_nil
          end
        end
      end

      context "when no digests exist" do
        it "completes without error" do
          expect { call }.not_to raise_error
        end
      end
    end

    context "when config.reaper = :ruby" do
      let(:reaper) { :ruby }

      it_behaves_like "v9 reaper behavior"
    end

    context "when config.reaper = :lua" do
      let(:reaper) { :lua }

      it_behaves_like "v9 reaper behavior"
    end

    context "when config.reaper = true" do
      let(:reaper) { true }

      it_behaves_like "v9 reaper behavior"
    end

    context "when config.reaper = :none" do
      let(:reaper) { :none }

      it "does nothing" do
        redis do |conn|
          conn.call("ZADD", "uniquejobs:digests", Time.now.to_f.to_s, digest)
        end

        expect { call }.not_to change { digests.count }
      end
    end
  end
end
