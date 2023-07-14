# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Digests do
  let(:digests) { described_class.new }

  shared_context "with a regular job" do
    let(:expected_keys) do
      {
        "uniquejobs:191cc66e8db74a712ca80180d846a8c0" => kind_of(Float),
        "uniquejobs:70091c2e18d6b45cd1a257a7b77c1dc0" => kind_of(Float),
        "uniquejobs:72254d80583af0f3cf1ff3cd8271c532" => kind_of(Float),
        "uniquejobs:7f1a663f444e9629ed73893541564351" => kind_of(Float),
        "uniquejobs:a1d714a6dacd9fcfe0aa6274af3d5ab4" => kind_of(Float),
        "uniquejobs:b9d8a7667ef91f07e9c5a735e08e0891" => kind_of(Float),
        "uniquejobs:ced55fba57e2d67b2422cacbe08896f4" => kind_of(Float),
        "uniquejobs:e284198d560db35309c4d1b49e325645" => kind_of(Float),
        "uniquejobs:e3544c3ca5a5b28141a1d161c70d04cb" => kind_of(Float),
        "uniquejobs:eb82e9e8057a8912a3f970c8768975f7" => kind_of(Float),
      }
    end

    before do
      (1..10).each do |arg|
        MyUniqueJob.perform_async(arg, arg)
      end
    end
  end

  shared_context "with an until_and_while_executing job" do
    let(:expected_keys) do
      {
        "uniquejobs:test1" => kind_of(Float),
        "uniquejobs:test1:RUN" => kind_of(Float),
        "uniquejobs:test10" => kind_of(Float),
        "uniquejobs:test10:RUN" => kind_of(Float),
        "uniquejobs:test2" => kind_of(Float),
        "uniquejobs:test2:RUN" => kind_of(Float),
        "uniquejobs:test3" => kind_of(Float),
        "uniquejobs:test3:RUN" => kind_of(Float),
        "uniquejobs:test4" => kind_of(Float),
        "uniquejobs:test4:RUN" => kind_of(Float),
        "uniquejobs:test5" => kind_of(Float),
        "uniquejobs:test5:RUN" => kind_of(Float),
        "uniquejobs:test6" => kind_of(Float),
        "uniquejobs:test6:RUN" => kind_of(Float),
        "uniquejobs:test7" => kind_of(Float),
        "uniquejobs:test7:RUN" => kind_of(Float),
        "uniquejobs:test8" => kind_of(Float),
        "uniquejobs:test8:RUN" => kind_of(Float),
        "uniquejobs:test9" => kind_of(Float),
        "uniquejobs:test9:RUN" => kind_of(Float),
      }
    end

    before do
      (1..10).each do |arg|
        SimulateLock.lock_until_and_while_executing("uniquejobs:test#{arg}", "jid#{arg}")
      end
    end
  end

  describe "#entries" do
    subject(:entries) { digests.entries(pattern: "*", count: 1000) }

    include_context "with a regular job" do
      it { is_expected.to match_array(expected_keys) }
    end
  end

  describe "#delete_by_digest" do
    subject(:delete_by_digest) { digests.delete_by_digest(digest) }

    context "with a regular job" do
      include_context "with a regular job"

      let(:digest) { "uniquejobs:a1d714a6dacd9fcfe0aa6274af3d5ab4" }

      before do
        allow(digests).to receive(:log_info)
      end

      it "deletes just the specific digest" do
        expect { delete_by_digest }.to change { digests.entries.size }.by(-1)
      end

      it "logs performance info" do
        delete_by_digest

        expect(digests).to have_received(:log_info)
          .with(
            a_string_starting_with("delete_by_digest(#{digest})")
            .and(matching(/completed in (\d+(\.\d+)?)ms/)),
          )
      end
    end

    context "with a runtime job" do
      include_context "with an until_and_while_executing job"

      let(:digest) { "uniquejobs:test3:RUN" }

      it "deletes just the specific digest" do
        unique_keys
        expect { delete_by_digest }.to change { digests.entries.size }.by(-1)
        expect(unique_keys).not_to include(
          %W[
            #{digest}:INFO
            #{digest}:LOCKED
            #{digest}:QUEUED
            #{digest}:PRIMED
          ],
        )
        expect(unique_keys).to include(digest.delete_suffix(":RUN"))
      end
    end
  end

  describe "#delete_by_pattern" do
    subject(:delete_by_pattern) { digests.delete_by_pattern(pattern, count: count) }

    let(:pattern) { "*" }
    let(:count)   { 1000 }

    include_context "with a regular job"

    before do
      allow(digests).to receive(:log_info)
    end

    it "deletes all matching digests" do
      expect(delete_by_pattern).to be_a(Integer)
      expect(digests.entries).to be_empty
    end

    it "logs performance info" do
      delete_by_pattern
      expect(digests)
        .to have_received(:log_info).with(
          a_string_starting_with("delete_by_pattern(*, count: 1000)")
          .and(matching(/completed in (\d+(\.\d+)?)ms/)),
        )
    end
  end
end
