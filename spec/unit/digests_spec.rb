# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs::Digests, redis: :redis do
  before do
    (1..10).each do |arg|
      MyUniqueJob.perform_async(arg, arg)
    end
  end

  let(:expected_keys) do
    [
      a_collection_including("uniquejobs:e739dadc23533773b920936336341d01", kind_of(Float)),
      a_collection_including("uniquejobs:56c68cab5038eb57959538866377560d", kind_of(Float)),
      a_collection_including("uniquejobs:8d9e83be14c033be4496295ec2740b91", kind_of(Float)),
      a_collection_including("uniquejobs:23e8715233c2e8f7b578263fcb8ac657", kind_of(Float)),
      a_collection_including("uniquejobs:6722965def15faf3c45cb9e66f994a49", kind_of(Float)),
      a_collection_including("uniquejobs:5bdd20fbbdda2fc28d6461e0eb1f76ee", kind_of(Float)),
      a_collection_including("uniquejobs:c658060a30b761bb12f2133cb7c3f294", kind_of(Float)),
      a_collection_including("uniquejobs:b34294c4802ee2d61c9e3e8dd7f2bab4", kind_of(Float)),
      a_collection_including("uniquejobs:06c3a5b63038c7b724b8603bb02ace99", kind_of(Float)),
      a_collection_including("uniquejobs:62c11d32fd69c691802579682409a483", kind_of(Float)),
    ]
  end

  describe ".all" do
    subject(:all) { described_class.all(pattern: "*", count: 1000) }

    it { is_expected.to match_array(expected_keys) }
  end

  describe ".del" do
    subject(:del) { described_class.del(digest: digest, pattern: pattern, count: count) }

    let(:digest)  { nil }
    let(:pattern) { nil }
    let(:count)   { 1000 }

    before do
      allow(described_class).to receive(:log_info)
    end

    context "when given a pattern" do
      let(:pattern) { "*" }

      it "deletes all matching digests" do
        expect(del).to be_a(Integer)
        expect(described_class.all).to match_array([])
      end

      it "logs performance info" do
        del
        expect(described_class)
          .to have_received(:log_info).with(
            a_string_starting_with("delete_by_pattern(*, count: 1000)")
            .and(matching(/completed in (\d+(\.\d+)?)ms/)),
          )
      end
    end

    context "when given a digest" do
      let(:digest) { "uniquejobs:62c11d32fd69c691802579682409a483" }

      it "deletes just the specific digest" do
        expect { del }.to change { described_class.all.size }.by(-1)
      end

      it "logs performance info" do
        del
        expect(described_class).to have_received(:log_info)
          .with(
            a_string_starting_with("delete_by_digest(#{digest})")
            .and(matching(/completed in (\d+(\.\d+)?)ms/)),
          )
      end
    end
  end
end
