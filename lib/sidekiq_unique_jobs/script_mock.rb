require 'pathname'
require 'digest/sha1'

module SidekiqUniqueJobs
  module ScriptMock
    module_function

    extend SingleForwardable
    def_delegator :SidekiqUniqueJobs, :connection

    def call(file_name, redis_pool, options = {})
      send(file_name, redis_pool, options)
    end

    def acquire_lock(redis_pool, options = {})
      connection(redis_pool) do |redis|
        unique_key = options[:keys][0]
        job_id     = options[:argv][0]
        expires    = options[:argv][1].to_i
        stored_jid = redis.get(unique_key)

        return stored_jid == job_id ? 1 : 0 if stored_jid

        if redis.set(unique_key, job_id, nx: true, ex: expires)
          redis.hsetnx('uniquejobs', job_id, unique_key)
          return 1
        else
          return 0
        end
      end
    end

    def release_lock(redis_pool, options = {})
      connection(redis_pool) do |redis|
        unique_key = options[:keys][0]
        job_id     = options[:argv][0]
        stored_jid = redis.get(unique_key)

        return -1 unless stored_jid
        return 0 unless stored_jid == job_id || stored_jid == '2'

        redis.del(unique_key)
        return 1
      end
    end

    def synchronize(redis_pool, options = {})
      connection(redis_pool) do |redis|
        unique_key = options[:keys][0]
        time       = options[:argv][0].to_i
        expires    = options[:argv][1].to_f

        stored_jid = redis.get(unique_key).to_i
        return 1 if redis.set(unique_key, time + expires, nx: true, ex: expires)

        stored_time = redis.get(unique_key)
        if stored_time && stored_time < time
          if redis.set(unique_key, time + expires, xx: true, ex: expires)
            return 1
          end
        end

        return 0
      end
    end
  end
  # rubocop:enable MethodLength
end
