# frozen_string_literal: true

class Issue432Worker
  include Sidekiq::Worker
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
    if redis.get("counter").to_i < 2
      log(arguments, :raise)
      raise "Need retry!"
    end
    log(arguments, :finish)
  ensure
    redis.incr "counter"
  end

  private

  def redis
    REDIS
  end

  def log(arguments, action)
    puts "      !!! #{action} #{arguments.inspect} "
    "\at #{Time.now.to_i - redis.get('start').to_i} sec, " \
    "counter is #{redis.get('counter')}"
  end
end
