require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Key do
  subject(:key) { described_class.new(digest_one) }

  let(:digest_one) { "abcdefab" }
  let(:digest_two) { "12334556" }

  let(:key_two) { described_class.new(digest_two) }

  its(:digest)    { is_expected.to eq(digest_one) }
  its(:queued)    { is_expected.to eq("#{digest_one}:QUEUED") }
  its(:primed)    { is_expected.to eq("#{digest_one}:PRIMED") }
  its(:locked)    { is_expected.to eq("#{digest_one}:LOCKED") }
  its(:digests)   { is_expected.to eq(SidekiqUniqueJobs::DIGESTS_ZSET) }
  its(:changelog) { is_expected.to eq(SidekiqUniqueJobs::CHANGELOG_ZSET) }
  its(:to_s)      { is_expected.to eq(digest_one) }
  its(:inspect)   { is_expected.to eq(digest_one) }
  its(:to_a) do
    is_expected.to eq(
      %W[
        #{digest_one}
        #{digest_one}:QUEUED
        #{digest_one}:PRIMED
        #{digest_one}:LOCKED
        unique:changelog
        unique:digests
      ]
    )
  end

  it { is_expected.to eq(key) }
  it { is_expected.not_to eq(key_two) }
end
