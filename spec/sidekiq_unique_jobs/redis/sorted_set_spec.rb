# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Redis::SortedSet do
  let(:entity)      { described_class.new(key) }
  let(:key)         { SidekiqUniqueJobs::Key.new(digest) }
  let(:digest)      { "digest:#{SecureRandom.hex(12)}" }
  let(:job_id)      { SecureRandom.hex(12) }
  let(:with_scores) { nil }

  describe "#entries" do
    subject(:entries) { entity.entries(with_scores: with_scores) }

    context "without entries" do
      it { is_expected.to match_array([]) }
    end

    context "with entries" do
      before { zadd(digest, now_f, job_id) }

      context "when given with_scores: false" do
        let(:with_scores) { false }

        it { is_expected.to match_array([job_id]) }
      end

      context "when given with_scores: true" do
        let(:with_scores) { true }

        it { is_expected.to match(a_hash_including(job_id => kind_of(Float))) }
      end
    end
  end

  describe "#count" do
    subject(:count) { entity.count }

    context "without entries" do
      it { is_expected.to be == 0 }
    end

    context "with entries" do
      before { zadd(digest, now_f, job_id) }

      it { is_expected.to be == 1 }
    end
  end

  describe "#score" do
    subject(:score) { entity.score(job_id) }

    context "without entries" do
      it { is_expected.to be_nil }
    end

    context "with entries" do
      before { zadd(digest, now_f, job_id) }

      it { is_expected.to be_within(0.5).of(now_f) }
    end
  end

  describe "#rank" do
    subject(:rank) { entity.rank(job_id) }

    context "without entries" do
      it { is_expected.to be_nil }
    end

    context "with entries" do
      before { zadd(digest, now_f, job_id) }

      it { is_expected.to be == 0 }
    end
  end
end
