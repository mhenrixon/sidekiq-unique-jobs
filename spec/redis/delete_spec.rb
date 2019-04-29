# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "delete.lua", redis: :redis do
  subject(:delete) { call_script(:delete, keys: key.to_a, argv: argv) }

  let(:argv) do
    [
      job_id,
      lock_ttl,
      lock_type,
    ]
  end
  let(:job_id)     { "jobid" }
  let(:lock_type)  { :until_executed }
  let(:digest)     { "uniquejobs:digest" }
  let(:key)        { SidekiqUniqueJobs::Key.new(digest) }
  let(:lock_ttl)   { nil }
  let(:locked_jid) { job_id }

  context "without existing locks" do
    before do
      delete
    end

    it_behaves_like "keys are removed by delete"
  end

  context "when a lock exists for another job_id" do
    let(:locked_jid)   { "anotherjobid" }

    before do
      call_script(:lock, keys: key.to_a, argv: [locked_jid, lock_ttl, lock_type, current_time])
      delete
    end

    it_behaves_like "keys are removed by delete"
  end

  context "when lock exists for the same job_id" do
    let(:locked_jid) { job_id }

    before do
      call_script(:lock, keys: key.to_a, argv: [job_id, lock_ttl, lock_type, current_time])
      delete
    end

    it_behaves_like "keys are removed by delete"
  end
end
# rubocop:enable RSpec/DescribeClass
