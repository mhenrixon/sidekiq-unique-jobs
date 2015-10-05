module SidekiqUniqueJobs
  module Unlockable
    module_function

    # rubocop:disable MethodLength
    def unlock(unique_key, jid, redis_pool = nil)
      result = Scripts.call(:release_lock, redis_pool,
                            keys: [unique_key],
                            argv: [jid])
      case result
      when 1
        Sidekiq.logger.debug { "successfully unlocked #{unique_key}" }
        true
      when 0
        Sidekiq.logger.debug { "expiring lock #{unique_key} is not owned by #{jid}" }
        false
      when -1
        Sidekiq.logger.debug { "#{unique_key} is not a known key" }
        false
      else
        fail "#{__method__} returned an unexpected value (#{result})"
      end
    end
    # rubocop:enable MethodLength
  end
end
