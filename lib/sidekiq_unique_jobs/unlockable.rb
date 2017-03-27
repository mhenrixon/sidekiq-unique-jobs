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
        logger.debug { "successfully unlocked #{unique_key}" }
        true
      when 0
        logger.debug { "expiring lock #{unique_key} is not owned by #{jid}" }
        false
      when -1
        logger.debug { "#{unique_key} is not a known key" }
        false
      else
        raise "#{calling_method} returned an unexpected value (#{result})"
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
