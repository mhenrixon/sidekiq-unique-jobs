# frozen_string_literal: true

require "concurrent/array"

module SimulateLock
  extend self

  @items = Concurrent::Array.new
  include SidekiqUniqueJobs::Timing

  def lock_jid(key, jid, ttl: nil, lock_type: :until_executed)
    raise ArgumentError, ":key needs to be a Key" unless key.is_a?(SidekiqUniqueJobs::Key)

    call_script(
      :lock,
      keys: key.to_a,
      argv: [jid, ttl, lock_type, SidekiqUniqueJobs.now_f],
    )
  end

  def simulate_lock(key, job_id)
    redis do |conn|
      conn.multi do |pipeline|
        pipeline.set(key.digest, job_id)
        pipeline.lpush(key.queued, job_id)
        pipeline.lpush(key.primed, job_id)
        pipeline.hset(key.locked, job_id, now_f)
        pipeline.zadd(key.digests, now_f, key.digest)
        pipeline.zadd(key.changelog, now_f, changelog_entry(key, job_id, "queue.lua", "Queued"))
        pipeline.zadd(key.changelog, now_f, changelog_entry(key, job_id, "lock.lua", "Locked"))
      end
    end
  end

  def changelog_entry(key, job_id, script, message)
    dump_json(
      digest: key.digest,
      job_id: job_id,
      script: script,
      message: message,
      time: now_f,
    )
  end

  def lock_until_executed(digest, jid, ttl = nil, **options)
    lock(
      parse_item(
        **options, digest: digest, jid: jid, lock_type: :until_executed, ttl: ttl,
      ),
    )
  end

  def lock_until_expired(digest, jid, ttl, **options)
    lock(
      parse_item(
        **options, digest: digest, jid: jid, lock_type: :until_expired, ttl: ttl,
      ),
    )
  end

  def lock_until_and_while_executing(digest, jid, ttl = nil, **options)
    lock(
      parse_item(
        **options, digest: digest, jid: jid, lock_type: :until_and_while_executing, ttl: ttl,
      ),
    )
    lock(
      parse_item(
        **options, digest: "#{digest}:RUN", jid: jid, lock_type: :until_and_while_executing, ttl: ttl,
      ),
    )
  end

  def lock_while_executing(digest, jid, ttl = nil, **options)
    lock(
      parse_item(
        **options, digest: "#{digest}:RUN", jid: jid, lock_type: :while_executing, ttl: ttl,
      ),
    )
  end

  def runtime_lock(digest, jid, ttl = nil, **options)
    lock(
      parse_item(
        **options, digest: digest, jid: jid, lock_type: :while_executing, ttl: ttl,
      ),
    )
    lock(
      parse_item(
        **options, digest: "#{digest}:RUN", jid: jid, lock_type: :while_executing, ttl: ttl,
      ),
    )
  end

  def lock(item)
    SidekiqUniqueJobs::Locksmith.new(item).lock
  end

  def unlock(item)
    SidekiqUniqueJobs::Locksmith.new(item).unlock
  end

  def parse_item(digest: "randomdigest", jid: "randomjid", lock_type: :until_executed, ttl: nil, **)
    item = {
      SidekiqUniqueJobs::UNIQUE_DIGEST => digest,
      SidekiqUniqueJobs::JID => jid,
      SidekiqUniqueJobs::LOCK_EXPIRATION => ttl,
      SidekiqUniqueJobs::LOCK => lock_type,
    }
    @items << item
    item
  end
end

RSpec.configure do |config|
  config.include SimulateLock
end
