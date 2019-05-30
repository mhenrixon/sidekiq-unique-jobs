# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Orphans::Reaper do
  let(:service)  { redis { |conn| described_class.new(conn) } }
  let(:digest)   { "digest" }
  let(:job_id)   { "job_id" }
  let(:item)     { raw_item }
  let(:raw_item) { { "class" => MyUniqueJob, "args" => [], "jid" => job_id, "unique_digest" => digest } }

  before do
    SidekiqUniqueJobs.disable!
    digests.add(digest)
  end

  after do
    SidekiqUniqueJobs.enable!
  end

  describe "#orphans" do
    subject(:orphans) { service.orphans }

    context "when scheduled" do
      let(:item) { raw_item.merge("at" => Time.now.to_f + 3_600) }

      context "without scheduled job" do
        it { is_expected.to match_array([digest]) }
      end

      context "with scheduled job" do
        before { push_item(item) }

        it { is_expected.to match_array([]) }
      end
    end

    context "when retried" do
      let(:item) { raw_item.merge("retry_count" => 2, "failed_at" => now_f) }

      context "without job in retry" do
        it { is_expected.to match_array([digest]) }
      end

      context "with job in retry" do
        before { zadd("retry", Time.now.to_f.to_s, dump_json(item)) }

        it { is_expected.to match_array([]) }
      end
    end

    context "when digest exists in a queue" do
      context "without enqueued job" do
        it { is_expected.to match_array([digest]) }
      end

      context "with enqueued job" do
        before { push_item(item) }

        it { is_expected.to match_array([]) }
      end
    end
  end

  describe ".call" do
    subject(:call) { described_class.call }

    around do |example|
      SidekiqUniqueJobs.use_config(reaper: reaper) do
        example.run
      end
    end

    before { digests.add(digest) }

    shared_examples "deletes orphans" do
      context "when scheduled" do
        let(:item) { raw_item.merge("at" => Time.now.to_f + 3_600) }

        context "without scheduled job" do
          it "keeps the digest" do
            expect { call }.to change { digests.count }.by(-1)
          end
        end

        context "with scheduled job" do
          before { push_item(item) }

          it "keeps the digest" do
            expect { call }.not_to change { digests.count }.from(1)
          end
        end
      end

      context "when retried" do
        let(:item) { raw_item.merge("retry_count" => 2, "failed_at" => now_f) }

        context "without job in retry" do
          it "keeps the digest" do
            expect { call }.to change { digests.count }.by(-1)
          end
        end

        context "with job in retry" do
          before { zadd("retry", Time.now.to_f.to_s, dump_json(item)) }

          it "keeps the digest" do
            expect { call }.not_to change { digests.count }.from(1)
          end
        end
      end

      context "when digest exists in a queue" do
        context "without enqueued job" do
          it "keeps the digest" do
            expect { call }.to change { digests.count }.by(-1)
          end
        end

        context "with enqueued job" do
          before { push_item(item) }

          it "keeps the digest" do
            expect { call }.not_to change { digests.count }.from(1)
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
