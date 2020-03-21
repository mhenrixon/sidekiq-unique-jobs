# frozen_string_literal: true

module LockSimulator
  module_function

  UNIQUE_ARGS = (1..2000).to_a

  def create_v6_locks(num = 20) # rubocop:disable Metrics/MethodLength
    old_digests = Array.new(num) { |n| "uniquejobs:v6-#{n}" }
    Sidekiq.redis do |conn|
      old_digests.each_slice(100) do |chunk|
        conn.pipelined do
          chunk.each do |digest|
            job_id = SecureRandom.hex(12)
            conn.sadd("unique:keys", digest)
            conn.set("#{digest}:EXISTS", job_id)
            conn.rpush("#{digest}:AVAILABLE", digest)
            conn.hset("#{digest}:GRABBED", job_id, Time.now.to_f)
          end
        end
      end
    end
  end

  def create_v7_locks(num = 20) # rubocop:disable Metrics/MethodLength
    old_digests = Array.new(num) { |n| "uniquejobs:v7-#{n}" }
    Sidekiq.redis do |conn| # rubocop:disable Metrics/BlockLength
      old_digests.each_slice(100) do |chunk|
        conn.pipelined do
          chunk.each do |digest|
            key    = SidekiqUniqueJobs::Key.new(digest)
            job_id = SecureRandom.hex(12)
            now_f  = Time.now.to_f

            conn.set(key.digest, job_id)
            conn.lpush(key.queued, job_id)
            conn.lpush(key.primed, job_id)
            conn.hset(key.locked, job_id, now_f)
            conn.zadd(key.digests, now_f, key.digest)
            conn.zadd(key.changelog, now_f, changelog_entry(key, job_id, "queue.lua", "Queued"))
            conn.zadd(key.changelog, now_f, changelog_entry(key, job_id, "lock.lua", "Locked"))
            conn.set(key.info,
                     dump_json(
                       "worker" => "MyCoolJob",
                       "queue" => "default",
                       "limit" => rand(5),
                       "timeout" => rand(20),
                       "ttl" => nil,
                       "lock" => SidekiqUniqueJobs.locks.keys.sample,
                       "lock_args" => UNIQUE_ARGS.sample(2),
                       "time" => now_f,
                     ))
          end
        end
      end
    end
  end

  def changelog_entry(key, job_id, script, message)
    dump_json(
      digest: key.digest,
      job_id: job_id,
      script: script,
      message: message,
      time: Time.now.to_f,
    )
  end

  def dump_json(msg = {})
    JSON.generate(msg)
  end
end
