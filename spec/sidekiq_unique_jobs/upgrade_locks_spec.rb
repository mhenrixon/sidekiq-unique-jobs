# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::UpgradeLocks do
  let(:old_digests) { Array.new(20) { |n| "uniquejobs:digest-#{n}" } }

  describe ".call" do
    subject(:call) { described_class.call }

    context "with v6 locks" do
      before do
        redis do |conn|
          old_digests.each_slice(100) do |chunk|
            conn.pipelined do |pipeline|
              chunk.each do |digest|
                job_id = SecureRandom.hex(12)
                pipeline.sadd("unique:keys", digest)
                pipeline.set("#{digest}:EXISTS", job_id)
                pipeline.rpush("#{digest}:AVAILABLE", digest)
                pipeline.hset("#{digest}:GRABBED", job_id, now_f)
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

        expect(exists("unique:keys")).to be(false)
        expect(digests.count).to eq(20)
      end
    end
  end
end
