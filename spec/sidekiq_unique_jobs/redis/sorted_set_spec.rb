# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Redis::SortedSet do
  let(:entity)      { described_class.new(digest) }
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

  describe "#add" do
    subject(:add) { entity.add(values) }

    context "when given an array of arrays" do
      let(:values) { [[1.0, "string"], [2.0, "other"]] }

      it { is_expected.to be == 2 }
    end

    context "when given a string entries" do
      let(:values) { "abcdef" }

      it { is_expected.to be == true }
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

  describe "#clear" do
    subject(:clear) { entity.clear }

    context "without entries" do
      it { is_expected.to be == 0 }
    end

    context "with entries" do
      before do
        values = (1..100).each_with_object([]) do |num, memo|
          memo.concat << [now_f, "#{job_id}#{num}"]
        end

        entity.add(values)
        zcard(digest)
      end

      it { is_expected.to be == 100 }
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
