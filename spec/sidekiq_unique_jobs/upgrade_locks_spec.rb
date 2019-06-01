# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::UpgradeLocks do
  let(:old_digests) { Array.new(20) { |n| "uniquejobs:digest-#{n}" } }

  describe ".call" do
    subject(:call) { redis { |conn| described_class.call(conn) } }

    context "with v6 locks" do
      before do
        redis do |conn|
          old_digests.each_slice(100) do |chunk|
            conn.pipelined do
              chunk.each do |digest|
                job_id = SecureRandom.hex(12)
                conn.sadd("unique:keys", digest)
                conn.set("#{digest}:EXISTS", job_id)
                conn.rpush("#{digest}:AVAILABLE", digest)
                conn.hset("#{digest}:GRABBED", job_id, now_f)
              end
            end
          end
        end
      end

      it "converts all locks to new format" do
        expect(call).to eq(20)

        old_digests.all? do |digest|
          expect(hlen("#{digest}:LOCKED")).to eq(1)
        end

        expect(exists("unique:keys")).to eq(false)
      end
    end
  end
end
