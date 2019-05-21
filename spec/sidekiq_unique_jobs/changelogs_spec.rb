# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Changelog do
  let(:entity) { described_class.new }
  let(:digest) { SecureRandom.hex(12) }
  let(:key)    { SidekiqUniqueJobs::Key.new(digest) }
  let(:job_id) { SecureRandom.hex(12) }

  describe "#exist?" do
    subject(:exist?) { entity.exist? }

    context "when no entries exist" do
      it { is_expected.to be == false }
    end

    context "when entries exist" do
      before { simulate_lock(key, job_id) }

      it { is_expected.to be == true }
    end
  end

  describe "#pttl" do
    subject(:pttl) { entity.pttl }

    context "when no entries exist" do
      it { is_expected.to be == -2 }
    end

    context "when entries exist without expiration" do
      before { simulate_lock(key, job_id) }

      it { is_expected.to be == -1 }
    end

    context "when entries exist with expiration" do
      before do
        simulate_lock(key, job_id)
        pexpire(key.changelog, 600)
      end

      it { is_expected.to be_within(20).of(600) }
    end
  end

  describe "#ttl" do
    subject(:ttl) { entity.ttl }

    context "when no entries exist" do
      it { is_expected.to be == -2 }
    end

    context "when entries exist without expiration" do
      before { simulate_lock(key, job_id) }

      it { is_expected.to be == -1 }
    end

    context "when entries exist with expiration" do
      before do
        simulate_lock(key, job_id)
        expire(key.changelog, 600)
      end

      it { is_expected.to be == 600 }
    end
  end

  describe "#expires?" do
    subject(:expires?) { entity.expires? }

    context "when no entries exist" do
      it { is_expected.to be == false }
    end

    context "when entries exist" do
      before do
        simulate_lock(key, job_id)
        expire(key.changelog, 600)
      end

      it { is_expected.to be == true }
    end
  end

  describe "#count" do
    subject(:count) { entity.count }

    context "when no entries exist" do
      it { is_expected.to be == 0 }
    end

    context "when entries exist" do
      before { simulate_lock(key, job_id) }

      it { is_expected.to be == 2 }
    end
  end

  describe "#entries" do
    subject(:entries) { entity.entries }

    context "when no entries exist" do
      it { is_expected.to match_array([]) }
    end

    context "when entries exist" do
      before { simulate_lock(key, job_id) }

      let(:locked_entry) do
        {
          "digest" => digest,
          "job_id" => job_id,
          "message" => "Locked",
          "script" => "lock.lua",
          "time" => kind_of(Float),
        }
      end
      let(:queued_entry) do
        {
          "digest" => digest,
          "job_id" => job_id,
          "message" => "Queued",
          "script" => "queue.lua",
          "time" => kind_of(Float),
        }
      end

      it { is_expected.to match_array([locked_entry, queued_entry]) }
    end
  end

  describe "#page" do
    subject(:page) { entity.page(cursor, pattern: pattern, page_size: page_size) }

    let(:cursor)    { 0 }
    let(:pattern)   { "*" }
    let(:page_size) { 1 }

    context "when no entries exist" do
      it { is_expected.to match_array([0, "0", []]) }
    end

    context "when entries exist" do
      before do
        flush_redis
        simulate_lock(key, job_id)
      end

      let(:locked_entry) do
        {
          "digest" => digest,
          "job_id" => job_id,
          "message" => "Locked",
          "script" => "lock.lua",
          "time" => kind_of(Float),
        }
      end
      let(:queued_entry) do
        {
          "digest" => digest,
          "job_id" => job_id,
          "message" => "Queued",
          "script" => "queue.lua",
          "time" => kind_of(Float),
        }
      end

      it { is_expected.to match_array([2, anything, a_collection_including(kind_of(Hash))]) }
    end
  end
end
