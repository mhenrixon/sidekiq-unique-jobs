# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Digests do
  let(:digests) { described_class.new }

  shared_context "with a regular job" do
    let(:expected_keys) do
      {
        "uniquejobs:0781b1f587a9a8d08773f21ed752caed" => kind_of(Float),
        "uniquejobs:09b3a42f77a75865bf27ac44e66bb4ef" => kind_of(Float),
        "uniquejobs:1c4c0bf2a8a1006c7610e4ef1f965f34" => kind_of(Float),
        "uniquejobs:236feda848cfbb1ae32d4d9af666349e" => kind_of(Float),
        "uniquejobs:77d1e23f18943bc048b48a01b85af0b3" => kind_of(Float),
        "uniquejobs:9fcaaf3e873f101a8d79e00e89bb3b36" => kind_of(Float),
        "uniquejobs:a47040c19b3741eaf912a96cd8bee728" => kind_of(Float),
        "uniquejobs:c85f45d715232cfff0505fb85ca92659" => kind_of(Float),
        "uniquejobs:cb5be91a66b83435281c23fe489f22b5" => kind_of(Float),
        "uniquejobs:e74bebbf569d620397688fded62c85d6" => kind_of(Float),
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

      let(:digest) { "uniquejobs:e74bebbf569d620397688fded62c85d6" }

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
      expect(digests.entries).to match_array([])
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
