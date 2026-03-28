# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Key do
  subject(:key) { described_class.new(digest_one) }

  let(:digest_one) { "uniquejobs:abcdefab" }
  let(:digest_two) { "uniquejobs:12334556" }

  let(:key_two) { described_class.new(digest_two) }

  its(:digest)  { is_expected.to eq(digest_one) }
  its(:locked)  { is_expected.to eq("#{digest_one}:LOCKED") }
  its(:digests) { is_expected.to eq(SidekiqUniqueJobs::DIGESTS) }
  its(:to_s)    { is_expected.to eq(digest_one) }
  its(:inspect) { is_expected.to eq(digest_one) }

  its(:to_a) do
    is_expected.to eq(["#{digest_one}:LOCKED", "uniquejobs:digests"])
  end

  it { is_expected.to eq(key) }
  it { is_expected.not_to eq(key_two) }

  describe ".working" do
    it "returns uniquejobs-namespaced key" do
      expect(described_class.working("host:123")).to eq("uniquejobs:working:host:123")
    end
  end

  describe ".heartbeat" do
    it "returns uniquejobs-namespaced key" do
      expect(described_class.heartbeat("host:123")).to eq("uniquejobs:heartbeat:host:123")
    end
  end
end
