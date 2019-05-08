# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "lock.lua", redis: :redis do
  subject(:lock) { call_script(:lock, key.to_a, argv_one) }

  let(:argv)           { [job_id_one, lock_ttl, lock_type, lock_limit] }
  let(:argv_one)       { [job_id_one, lock_ttl, lock_type, lock_limit] }
  let(:argv_two)       { [job_id_two, lock_ttl, lock_type, lock_limit] }

  let(:job_id_one)     { "job_id_one" }
  let(:job_id_two)     { "job_id_two" }
  let(:primed_jid_one) { rpoplpush(key.queued, key.primed) }
  let(:primed_jid_two) { rpoplpush(key.queued, key.primed) }
  let(:lock_type)      { :until_executed }
  let(:digest)         { "uniquejobs:digest" }
  let(:key)            { SidekiqUniqueJobs::Key.new(digest) }
  let(:lock_ttl)       { nil }
  let(:locked_jid)     { job_id_one }
  let(:current_time)   { SidekiqUniqueJobs::Timing.current_time }
  let(:lock_limit)    { 1 }

  module SidekiqUniqueJobs
    class Redis
      class Entity
        include SidekiqUniqueJobs::Connection
        include SidekiqUniqueJobs::Testing::Redis

        attr_reader :key

        def initialize(key)
          @key = key
        end

        def exist?
          exists(key)
        end

        def pttl
          pttl(key)
        end

        def ttl
          ttl(key)
        end
      end

      class List < Entity
        def entries
          lrange(key, 0, -1)
        end
      end

      class Hash < Entity
      end

      class Set < Entity
        def entries
          smembers(key)
        end
      end

      class SortedSet < Entity
        def entries
          zrange(key, 0, -1, with_scores: with_scores)
        end

        def rank(member)
          zrank(key, member)
        end

        def score(member)
          zscore(key, member)
        end
      end

      class Changelog < SortedSet

      end

      class Key < Entity
        def value
          get(key)
        end
      end

      class Lock
        attr_reader :key

        def new(key)
          raise ArgumentError, "key is not a SidekiqUniqueJobs::Key" unless key.is_a?(SidekiqUniqueJobs::Key)
          @key = key
        end

        def all_jids
          multi do
            lrange(key.queued, 0, -1)
            lrange(key.primed, 0, -1)
            hkeys(grabbed_key)
          end.flatten
        end

        def jids
        end

        def digest_key
          @digest_key ||= Redis::Key.new(key.digest)
        end

        def queued_list
          @queued_list ||= Redis::List.new(key.queued)
        end

        def primed_list
          @primed_list ||= Redis::List.new(key.primed)
        end

        def locked_hash
          @locked_hash ||= Redis::List.new(key.locked)
        end

        def changelog
          @changelog ||= Redis::SortedSet.new(key.changelog)
        end
      end
    end
  end


  context "when not queued" do
    it "updates Redis correctly" do
      expect { lock }.to change { zcard(key.changelog) }.by(1)

      expect(lock).to eq(job_id_one)
      expect(get(key.digest)).to eq(nil)
      expect(pttl(key.digest)).to eq(-2) # key does not exist
      expect(llen(key.queued)).to eq(0)
      expect(lrange(key.primed, 0, -1)).to match_array([])
      expect(llen(key.primed)).to eq(0)
      expect(exists(key.queued)).to eq(false)
      expect(exists(key.primed)).to eq(false)
      expect(exists(key.locked)).to eq(true)
      expect(hget(key.locked, job_id_one).to_f).to be_within(0.5).of(current_time)
    end
  end

  context "when queued" do
    before do
      call_script(:queue, key.to_a, argv_one)
    end

    it "updates Redis correctly" do
      expect { lock }.to change { zcard(key.changelog) }.by(1)

      expect(lock).to eq(job_id_one)
      expect(get(key.digest)).to eq(job_id_one)
      expect(pttl(key.digest)).to eq(-1) # key exists without pttl
      expect(llen(key.queued)).to eq(1)
      expect(llen(key.primed)).to eq(0)
      expect(exists(key.queued)).to eq(true)
      expect(exists(key.primed)).to eq(false)
      expect(exists(key.locked)).to eq(true)
    end
  end

  context "when primed" do
    before do
      call_script(:queue, key.to_a, argv_one)
      primed_jid_one
    end

    it "updates Redis correctly" do
      expect { lock }.to change { zcard(key.changelog) }.by(1)

      expect(lock).to eq(job_id_one)
      expect(get(key.digest)).to eq(job_id_one)
      expect(pttl(key.digest)).to eq(-1) # key exists without pttl
      expect(llen(key.queued)).to eq(0)
      expect(llen(key.primed)).to eq(0)
      expect(exists(key.queued)).to eq(false)
      expect(exists(key.primed)).to eq(false)
      expect(exists(key.locked)).to eq(true)
    end
  end

  context "when locked by another job" do
    context "with lock_limit 1" do
      before do
        call_script(:queue, key.to_a, argv_two)
        primed_jid_two
        call_script(:lock, key.to_a, argv_two)
      end

      it "updates Redis correctly" do
        expect { lock }.to change { zcard(key.changelog) }.by(1)

        expect(lock).to eq(nil)
        expect(get(key.digest)).to eq(job_id_two)
        expect(pttl(key.digest)).to eq(-1) # key exists without pttl
        expect(llen(key.queued)).to eq(0)
        expect(llen(key.primed)).to eq(0)
        expect(exists(key.primed)).to eq(false)
        expect(exists(key.locked)).to eq(true)
        expect(hget(key.locked, job_id_two).to_f).to be_within(0.1).of(current_time)
      end
    end

    context "with lock_limit 2" do
      let(:lock_limit) { 2 }

      before do
        call_script(:queue, key.to_a, argv_two)
        primed_jid_two
        call_script(:lock, key.to_a, argv_two)

        call_script(:queue, key.to_a, argv_one)
        primed_jid_one
      end

      it "updates Redis correctly" do
        expect { lock }.to change { zcard(key.changelog) }.by(1)

        expect(lock).to eq(job_id_one)
        expect(get(key.digest)).to eq(job_id_one)
        expect(pttl(key.digest)).to eq(-1) # key exists without pttl
        expect(llen(key.queued)).to eq(0)
        expect(llen(key.primed)).to eq(0)
        expect(exists(key.primed)).to eq(false)
        expect(exists(key.locked)).to eq(true)
        expect(hlen(key.locked)).to eq(2)
        expect(hget(key.locked, job_id_two).to_f).to be_within(0.2).of(current_time)
      end
    end
  end

  context "when locked by same job" do
    before do
      call_script(:queue, key.to_a, argv_one)
      primed_jid_one

      hset(key.locked, job_id_one, current_time)
    end

    it "updates Redis correctly" do
      expect { lock }.to change { zcard(key.changelog) }.by(1)

      expect(lock).to eq(job_id_one)
      expect(get(key.digest)).to eq(job_id_one)
      expect(pttl(key.digest)).to eq(-1) # key exists without pttl
      expect(llen(key.queued)).to eq(0)
      expect(lrange(key.primed, 0, -1)).to match_array([job_id_one])
      expect(rpop(key.primed)).to eq(job_id_one)
      expect(exists(key.primed)).to eq(false)
      expect(exists(key.locked)).to eq(true)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
