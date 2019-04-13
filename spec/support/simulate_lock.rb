require "concurrent/array"

module SimulateLock
  extend self
  @items = Concurrent::Array.new

  def lock_until_executed(digest, jid, ttl = nil)
    lock()
  end

  def lock_until_expired(digest, jid, ttl)
    item = get_item(digest: digest, jid: jid, lock_type: :until_expired, expiration: ttl)
    lock(item)
  end

  def lock_until_and_while_executing(digest, jid, ttl)
    item = get_item(digest: digest, jid: jid, lock_type: :until_expired, expiration: ttl)
    lock(item)
  end

  def lock_while_executing(digest, jid, ttl = nil)
    lock(digest: digest, jid: "randomjid", lock_type: :while_executing, expiration: nil)
  end

  def runtime_lock(digest, jid, ttl = nil)

  end

  def lock(item)
    Locksmith.new(item).lock
  end

  def get_item(digest: "randomdigest", jid: "randomjid", lock_type: :until_executed, expiration: nil)
    item = {
      UNIQUE_DIGEST_KEY => digest,
      JID_KEY => jid,
      LOCK_EXPIRATION_KEY => expiration,
      LOCK_KEY => lock_type,
    }
    @items << item
    item
  end
end
