# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Locksmith, perf: true do
  let(:locksmith_one)   { described_class.new(item_one) }
  let(:locksmith_two)   { described_class.new(item_two) }

  let(:jid_one)      { "maaaahjid" }
  let(:jid_two)      { "jidmayhem" }
  let(:lock_ttl)     { nil }
  let(:lock_type)    { "until_executed" }
  let(:digest)       { "uniquejobs:randomvalue" }
  let(:key)          { SidekiqUniqueJobs::Key.new(digest) }
  let(:lock)         { SidekiqUniqueJobs::Lock.new(key) }
  let(:lock_timeout) { 0 }
  let(:lock_limit)   { 1 }
  let(:item_one) do
    {
      "jid" => jid_one,
      "unique_digest" => digest,
      "lock_ttl" => lock_ttl,
      "lock" => lock_type,
      "lock_timeout" => lock_timeout,
      "lock_limit" => lock_limit,
    }
  end
  let(:item_two) { item_one.merge("jid" => jid_two) }

  specify { expect { locksmith_one.lock {} }.to perform_under(3).ms }
  specify { expect { locksmith_one.lock {} }.to perform_allocation(Array => 92, Hash => 14).bytes }
end
