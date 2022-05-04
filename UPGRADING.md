# Upgrading

## v7.1.0

### Reflection API

SidekiqUniqueJobs do not log by default anymore. Instead I have a reflection API that I shamelessly borrowed from Rpush.

To use the new notification/reflection system please define them as follows in an initializer of your choosing.

```ruby
SidekiqUniqueJobs.reflect do |on|
  # Only raised when you have defined such a callback
  on.after_unlock_callback_failed do |job_hash|
    logger.warn(job_hash.merge(message: "Unlock callback failed"))
  end

  # This job is skipped because it is a duplicate
  on.duplicate do |job_hash|
    logger.warn(job_hash.merge(message: "Duplicate Job"))
  end

  # This means your code broke and we caught the execption to provide this reflection for you. It allows your to gather metrics and details about the error. Those details allow you to act on it as you see fit.
  on.execution_failed do |job_hash, exception = nil|
    message = "Execution failed"
    message = message + "(#{exception.message})" if exception
    logger.warn(job_hash.merge(message: message)
  end

  # Failed to acquire lock in a timely fashion
  on.lock_failed do |job_hash|
    logger.warn(job_hash.merge(message: "Lock failed"))
  end

  # In case you want to collect metrics
  on.locked do |job_hash|
    logger.debug(job_hash.merge(message: "Lock success"))
  end

  # When your conflict strategy is to reschedule and it failed
  on.reschedule_failed do |job_hash|
    logger.debug(job_hash.merge(message: "Reschedule failed"))
  end

  # When your conflict strategy is to reschedule and it failed
  # Mostly for metrics I guess
  on.rescheduled do |job_hash|
    logger.debug(job_hash.merge(message: "Reschedule success"))
  end

  # You asked to wait for a lock to be achieved but we timed out waiting
  on.timeout do |job_hash|
    logger.warn(job_hash.merge(message: "Oh no! Timeout!! Timeout!!"))
  end

  # The current worker isn't part of this sidekiq servers workers
  on.unknown_sidekiq_worker do |job_hash|
    logger.warn(job_hash.merge(message: "WAT!? Why? What is this worker?"))
  end

  # Unlock failed! Not good
  on.unlock_failed do |job_hash|
    logger.warn(job_hash.merge(message: "Unlock failed"))
  end

  # Unlock was successful, perhaps mostly interesting for metrics
  on.unlocked do |job_hash|
    logger.warn(job_hash.merge(message: "Unlock success"))
  end
```

You don't need to configure them all. Some of them are just informational, some of them more for metrics and a couple of them (failures, timeouts) might be of real interest.

I leave it up to you to decided what to do about it.

### Reaper Resurrector

In [#604](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/604) a reaper resurrector was added. This is configured by default so that if the current reaper process dies, another one kicks off again.

With the recent fixes in [#616](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/616) there should be even less need for reaping.

