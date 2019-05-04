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
      argv: [jid, ttl, lock_type, SidekiqUniqueJobs::Timing.current_time],
    )
  end

  def simulate_lock(key, job_id)
    redis do |conn|
      conn.multi do
        conn.set(key.digest, job_id)
        conn.lpush(key.queued, job_id)
        conn.lpush(key.primed, job_id)
        conn.hset(key.locked, job_id, current_time)
      end
    end
  end

  def lock_until_executed(digest, jid, ttl = nil)
    item = get_item(digest: digest, jid: jid, lock_type: :until_executed, ttl: ttl)
    lock(item)
  end

  def lock_until_expired(digest, jid, ttl)
    item = get_item(digest: digest, jid: jid, lock_type: :until_expired, ttl: ttl)
    lock(item)
  end

  def lock_until_and_while_executing(digest, jid, ttl = nil)
    item = get_item(digest: digest, jid: jid, lock_type: :until_expired, ttl: ttl)
    lock(item)
  end

  def lock_while_executing(digest, jid, ttl = nil)
    digest = digest.dup + ":RUN"
    item = get_item(digest: digest, jid: jid, lock_type: :while_executing, ttl: ttl)
    lock(item)
  end

  def runtime_lock(digest, jid, ttl = nil)
    item = get_item(digest: digest, jid: jid, lock_type: :while_executing, ttl: ttl)
    lock(item)
    item = get_item(digest: "#{digest}:RUN", jid: "randomjid", lock_type: :while_executing, ttl: ttl)
    lock(item)
  end

  def lock(item)
    Locksmith.new(item).lock
  end

  def unlock(item)
    Locksmith.new(item).unlock
  end

  def get_item(digest: "randomdigest", jid: "randomjid", lock_type: :until_executed, ttl: nil)
    item = {
      UNIQUE_DIGEST_KEY => digest,
      JID_KEY => jid,
      LOCK_EXPIRATION_KEY => ttl,
      LOCK_KEY => lock_type,
    }
    @items << item
    item
  end
end

RSpec.configure do |config|
  config.include SimulateLock
end
