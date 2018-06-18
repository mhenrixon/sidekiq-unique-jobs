module SidekiqHelpers
  def redis(&block)
    pool = if respond_to?(:redis_pool)
             redis_pool
           else
             nil
           end
    SidekiqUniqueJobs.connection(nil, &block)
  end

  def zcard(queue)
    redis { |conn| conn.zcard(queue) }
  end

  def zcount(queue, time)
    redis { |conn| conn.zcount(queue, -1, time) }
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
    return redis(&:keys) if pattern.nil?
    redis { |conn| conn.keys(pattern)  }
  end

  def ttl(key)
    redis { |conn| conn.ttl(key) }
  end
end

RSpec.configure do |config|
  config.include SidekiqHelpers
end
