# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::UpgradeLocks do
  describe ".call" do
    subject(:call) { described_class.call }

    context "with v8 locks" do
      let(:digest) { "uniquejobs:v8migration-test" }
      let(:jid) { "migration-jid-123" }

      before do
        redis do |conn|
          # Simulate v8 key structure
          conn.call("SET", digest, jid)
          conn.call("LPUSH", "#{digest}:QUEUED", jid)
          conn.call("LPUSH", "#{digest}:PRIMED", jid)
          conn.call("HSET", "#{digest}:LOCKED", jid, Time.now.to_f.to_s)
          conn.call("SET", "#{digest}:INFO", '{"type":"until_executed"}')
          conn.call("ZADD", "uniquejobs:digests", Time.now.to_f.to_s, digest)

          # :RUN variants
          conn.call("SET", "#{digest}:RUN", jid)
          conn.call("LPUSH", "#{digest}:RUN:QUEUED", jid)
          conn.call("LPUSH", "#{digest}:RUN:PRIMED", jid)
          conn.call("HSET", "#{digest}:RUN:LOCKED", jid, Time.now.to_f.to_s)
          conn.call("SET", "#{digest}:RUN:INFO", '{"type":"while_executing"}')
        end
      end

      it "removes obsolete v8 keys" do
        call

        redis do |conn|
          # Obsolete keys should be gone
          expect(conn.call("EXISTS", digest)).to eq(0)
          expect(conn.call("EXISTS", "#{digest}:QUEUED")).to eq(0)
          expect(conn.call("EXISTS", "#{digest}:PRIMED")).to eq(0)
          expect(conn.call("EXISTS", "#{digest}:INFO")).to eq(0)
          expect(conn.call("EXISTS", "#{digest}:RUN")).to eq(0)
          expect(conn.call("EXISTS", "#{digest}:RUN:QUEUED")).to eq(0)
          expect(conn.call("EXISTS", "#{digest}:RUN:PRIMED")).to eq(0)
          expect(conn.call("EXISTS", "#{digest}:RUN:LOCKED")).to eq(0)
          expect(conn.call("EXISTS", "#{digest}:RUN:INFO")).to eq(0)

          # LOCKED hash should be preserved
          expect(conn.call("HEXISTS", "#{digest}:LOCKED", jid)).to eq(1)

          # digests ZSET should be preserved
          expect(conn.call("ZSCORE", "uniquejobs:digests", digest)).not_to be_nil
        end
      end
    end

    context "with expiring digests" do
      before do
        redis do |conn|
          conn.call("ZADD", "uniquejobs:expiring_digests", (Time.now + 3600).to_f.to_s, "uniquejobs:exp1")
          conn.call("ZADD", "uniquejobs:expiring_digests", (Time.now + 7200).to_f.to_s, "uniquejobs:exp2")
        end
      end

      it "merges expiring_digests into digests and removes the old ZSET" do
        call

        redis do |conn|
          # Entries should be in digests now
          expect(conn.call("ZSCORE", "uniquejobs:digests", "uniquejobs:exp1")).not_to be_nil
          expect(conn.call("ZSCORE", "uniquejobs:digests", "uniquejobs:exp2")).not_to be_nil

          # expiring_digests should be gone
          expect(conn.call("EXISTS", "uniquejobs:expiring_digests")).to eq(0)
        end
      end
    end

    context "when already upgraded" do
      it "skips the second run" do
        described_class.call # first run
        expect { described_class.call }.not_to raise_error # second run is a no-op
      end
    end
  end
end
