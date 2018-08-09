# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidekiq::RetrySet, redis: :redis do
  let(:locksmith)       { SidekiqUniqueJobs::Locksmith.new(item) }
  let(:args)            { [1, 2] }
  let(:worker_class)    { MyUniqueJob }
  let(:jid)             { 'ajobid' }
  let(:lock)            { :until_executed }
  let(:lock_expiration) { 7_200 }
  let(:queue)           { :customqueue }
  let(:retry_at)        { Time.now.to_f + 360 }
  let(:unique_digest)   { 'uniquejobs:9e9b5ce5d423d3ea470977004b50ff84' }
  let(:item) do
    {
      'args' => args,
      'class' => worker_class,
      'failed_at' => Time.now.to_f,
      'jid' => jid,
      'lock' => lock,
      'lock_expiration' => lock_expiration,
      'queue' => queue,
      'retry_at' => retry_at,
      'retry_count' => 1,
      'unique_digest' => unique_digest,
    }
  end

  before do
    zadd('retry', retry_at.to_s, Sidekiq.dump_json(item))
    expect(retry_count).to eq(1)
  end

  context 'when a job is locked' do
    before do
      expect(locksmith.lock).to eq(jid)
      expect(unique_keys).to match_array(%W[
                                           #{unique_digest}:EXISTS
                                           #{unique_digest}:GRABBED
                                         ])
      expect(ttl("#{unique_digest}:EXISTS")).to eq(lock_expiration)
      expect(ttl("#{unique_digest}:GRABBED")).to eq(-1)
    end

    it 'can be put back on queue' do
      expect { described_class.new.retry_all }
        .to change { queue_count(queue) }
        .from(0).to(1)
    end
  end
end
