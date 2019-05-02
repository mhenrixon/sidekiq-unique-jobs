# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "delete.lua", redis: :redis do
  subject(:delete) { call_script(:delete, keys: key.to_a) }

  let(:argv) do
    [
      job_id,
      lock_ttl,
      lock_type,
      current_time,
      concurrency,
    ]
  end
  let(:job_id)      { "jobid" }
  let(:lock_type)   { :until_executed }
  let(:digest)      { "uniquejobs:digest" }
  let(:key)         { SidekiqUniqueJobs::Key.new(digest) }
  let(:lock_ttl)    { nil }
  let(:locked_jid)  { job_id }
  let(:concurrency) { 1 }

  before do
    call_script(:prepare, key.to_a, argv)
    lpush(key.obtained, key.digest)
    call_script(:obtain, key.to_a, argv)

    delete
  end

  context "without existing locks" do
    before do
      delete
    end

    it "deletes keys in redis" do
      expect(key.digest).not_to exist
      expect(key.free_set).not_to exist
      expect(key.free_zet).not_to exist
      expect(key.held_set).not_to exist
      expect(key.held_zet).not_to exist
      expect(key.locked).not_to exist
    end
  end

  context "when a lock exists for another job_id" do
    let(:locked_jid)   { "anotherjobid" }

    it "deletes keys in redis" do
      expect(key.digest).not_to exist
      expect(key.free_set).not_to exist
      expect(key.free_zet).not_to exist
      expect(key.held_set).not_to exist
      expect(key.held_zet).not_to exist
      expect(key.locked).not_to exist
    end
  end

  context "when lock exists for the same job_id" do
    let(:locked_jid) { job_id }

    it "deletes keys in redis" do
      expect(key.digest).not_to exist
      expect(key.free_set).not_to exist
      expect(key.free_zet).not_to exist
      expect(key.held_set).not_to exist
      expect(key.held_zet).not_to exist
      expect(key.locked).not_to exist
    end
  end
end
# rubocop:enable RSpec/DescribeClass
