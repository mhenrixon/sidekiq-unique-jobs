# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs::Digests do
  let(:digests) { described_class.new }
  let(:expected_keys) do
    {
      "uniquejobs:e739dadc23533773b920936336341d01" => kind_of(Float),
      "uniquejobs:56c68cab5038eb57959538866377560d" => kind_of(Float),
      "uniquejobs:8d9e83be14c033be4496295ec2740b91" => kind_of(Float),
      "uniquejobs:23e8715233c2e8f7b578263fcb8ac657" => kind_of(Float),
      "uniquejobs:6722965def15faf3c45cb9e66f994a49" => kind_of(Float),
      "uniquejobs:5bdd20fbbdda2fc28d6461e0eb1f76ee" => kind_of(Float),
      "uniquejobs:c658060a30b761bb12f2133cb7c3f294" => kind_of(Float),
      "uniquejobs:b34294c4802ee2d61c9e3e8dd7f2bab4" => kind_of(Float),
      "uniquejobs:06c3a5b63038c7b724b8603bb02ace99" => kind_of(Float),
      "uniquejobs:62c11d32fd69c691802579682409a483" => kind_of(Float),
    }
  end

  before do
    (1..10).each do |arg|
      MyUniqueJob.perform_async(arg, arg)
    end
  end

  describe "#entries" do
    subject(:entries) { digests.entries(pattern: "*", count: 1000) }

    it { is_expected.to match_array(expected_keys) }
  end

  describe "#del" do
    subject(:del) { digests.del(digest: digest, pattern: pattern, count: count) }

    let(:digest)  { nil }
    let(:pattern) { nil }
    let(:count)   { 1000 }

    before do
      allow(digests).to receive(:log_info)
    end

    context "when given nothing" do
      let(:digest) { nil }
      let(:pattern) { nil }

      it { expect { del }.to raise_error(ArgumentError, "#del requires either a :digest or a :pattern") }
    end

    context "when given a pattern" do
      let(:pattern) { "*" }

      it "deletes all matching digests" do
        expect(del).to be_a(Integer)
        expect(digests.entries).to match_array([])
      end

      it "logs performance info" do
        del
        expect(digests)
          .to have_received(:log_info).with(
            a_string_starting_with("delete_by_pattern(*, count: 1000)")
            .and(matching(/completed in (\d+(\.\d+)?)ms/)),
          )
      end
    end

    context "when given a digest" do
      let(:digest) { "uniquejobs:62c11d32fd69c691802579682409a483" }

      it "deletes just the specific digest" do
        expect { del }.to change { digests.entries.size }.by(-1)
      end

      it "logs performance info" do
        del
        expect(digests).to have_received(:log_info)
          .with(
            a_string_starting_with("delete_by_digest(#{digest})")
            .and(matching(/completed in (\d+(\.\d+)?)ms/)),
          )
      end
    end
  end
end
