# frozen_string_literal: true

module SidekiqHelpers
  include SidekiqUniqueJobs::Connection

  def dead_count
    zcard("dead")
  end

  def get(key)
    redis { |conn| conn.get(key) }
  end

  def set(key, value, options = {})
    redis { |conn| conn.set(key, value, options) }
  end

  def hexists(hash, key)
    redis { |conn| conn.hexists(hash, key) }
  end

  def hlen(hash, key)
    redis { |conn| conn.hlen(hash, key) }
  end

  def keys(pattern = nil)
    SidekiqUniqueJobs::Util.keys(pattern)
  end

  def push_item(item = {})
    Sidekiq::Client.push(item)
  end

  def queue_count(queue)
    redis { |conn| conn.llen("queue:#{queue}") }
  end

  def retry_count
    zcard("retry")
  end

  def scard(queue)
    redis { |conn| conn.scard(queue) }
  end

  def schedule_count
    zcard("schedule")
  end

  def schedule_count_at(max = Time.now.to_f + 2 * 60)
    zcount("schedule", "-inf", max)
  end

  def set_key(key, value)
    redis { |conn| conn.set(key, value) }
  end

  def ttl(key)
    redis { |conn| conn.ttl(key) }
  end

  def unique_digests
    smembers("unique:keys")
  end

  def smembers(key)
    redis { |conn| conn.smembers(key) }
  end

  def lrange(key, start_pos, end_pos)
    redis { |conn| conn.lrange(key, start_pos, end_pos) }
  end

  def hget(key, value)
    redis { |conn| conn.hget(key, value) }
  end

  def unique_keys
    keys("uniquejobs:*")
  end

  def zadd(queue, timestamp, item)
    redis { |conn| conn.zadd(queue, timestamp, item) }
  end

  def zcard(queue)
    redis { |conn| conn.zcard(queue) }
  end

  def zcount(queue, min = "-inf", max = "+inf")
    redis { |conn| conn.zcount(queue, min, max) }
  end

  def call_script(file_name, keys: [], argv: [])
    SidekiqUniqueJobs::Scripts.call(file_name, nil, keys: keys, argv: argv)
  end
end

RSpec.configure do |config|
  config.include SidekiqHelpers
end
