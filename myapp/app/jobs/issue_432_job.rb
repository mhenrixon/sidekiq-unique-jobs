# frozen_string_literal: true

class Issue432Job
  include Sidekiq::Job
  sidekiq_retry_in { 3 }

  sidekiq_options(
    queue: "default",
    lock: :while_executing,
    lock_timeout: 60,
    retry: 2,
    on_conflict: :log,
    unique_args: lambda do |args|
      [
        args[0],
      ]
    end,
  )

  def perform(*arguments)
    log(arguments, :start)
    sleep 3
    if redis.call("GET", "counter").to_i < 2
      log(arguments, :raise)
      raise "Need retry!"
    end
    log(arguments, :finish)
  ensure
    redis.call("INCR", "counter")
  end

  private

  def redis
    @redis ||= RedisClient.new(url: ENV.fetch("REDIS_URL", nil))
  end

  def log(arguments, action)
    Rails.logger.debug do
      "      !!! #{action} #{arguments.inspect} " \
        "at #{Time.now.to_i - redis.call('GET', 'start').to_i} sec, " \
        "counter is #{redis.call('GET', 'counter')}"
    end
  end
end
