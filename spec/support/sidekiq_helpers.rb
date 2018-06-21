# frozen_string_literal: true

module SidekiqHelpers
  include SidekiqUniqueJobs::Connection

  def zcard(queue)
    redis { |conn| conn.zcard(queue) }
  end

  def zcount(queue, time)
    redis { |conn| conn.zcount(queue, -1, time) }
  end

  def get_key(key)
    redis { |conn| conn.get(key) }
  end

  def set_key(key, value)
    redis { |conn| conn.set(key, value) }
  end

  def dead_count
    zcard('dead')
  end

  def schedule_count
    zcard('schedule')
  end

  def schedule_count_at(time = Time.now.to_f + 2 * 60)
    zcount('schedule', time)
  end

  def queue_count(queue)
    redis { |conn| conn.llen("queue:#{queue}") }
  end

  def keys(pattern = nil)
    SidekiqUniqueJobs::Util.keys(pattern)
  end

  def unique_keys
    keys('uniquejobs:*')
  end

  def ttl(key)
    redis { |conn| conn.ttl(key) }
  end
end

RSpec.configure do |config|
  config.include SidekiqHelpers
end
