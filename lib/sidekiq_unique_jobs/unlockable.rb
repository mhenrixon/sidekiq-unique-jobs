module SidekiqUniqueJobs
  module Unlockable
    module_function

    def unlock(item)
      unlock_by_key(item[UNIQUE_DIGEST_KEY], item[JID_KEY])
    end

    def unlock_by_key(unique_key, jid, redis_pool = nil)
      result = Scripts.call(:release_lock, redis_pool, keys: [unique_key], argv: [jid])
      after_unlock(result, __method__, unique_key, jid)
    end

    def after_unlock(result, calling_method, unique_key, jid) # rubocop:disable Metrics/MethodLength
      ensure_job_id_removed(jid)

      case result
      when 1
        logger.debug { "#{calling_method}: successfully unlocked #{unique_key} (del Ok, hdel Ok)" }
        true
      when 2
        logger.debug { "#{calling_method}: successfully unlocked #{unique_key} (del Ok, hdel failed)" }
        true # previously considered a success
      when 3
        logger.debug { "#{calling_method}: successfully unlocked #{unique_key} (del failed, hdel Ok)" }
        true # previously considered a success
      when 4
        logger.debug { "#{calling_method}: successfully unlocked #{unique_key} (del failed, hdel failed)" }
        true # previously considered a success
      when 0
        logger.debug { "#{calling_method}: expiring lock #{unique_key} is not owned by #{jid}" }
        false
      when -1
        logger.debug { "#{calling_method}: #{unique_key} is not a known key" }
        false
      else
        msg = "#{calling_method}: returned an unexpected value (#{result})"
        logger.debug { msg }
        raise msg
      end
    end

    def ensure_job_id_removed(jid)
      Sidekiq.redis { |redis| redis.hdel(SidekiqUniqueJobs::HASH_KEY, jid) }
    end

    def logger
      Sidekiq.logger
    end
  end
end
