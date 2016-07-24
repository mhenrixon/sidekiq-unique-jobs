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
        expires    = options[:argv][1]

        stored_jid = redis.get(unique_key)
        if stored_jid
          if stored_jid == job_id
            return 1
          else
            return 0
          end
        end

        if redis.set(unique_key, job_id, nx: true, ex: expires)
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
        if stored_jid
          if stored_jid == job_id || stored_jid == '2'
            redis.del(unique_key)
            redis.hdel('uniquejobs', job_id)
            return 1
          else
            return 0
          end
        else
          return -1
        end
      end
    end

    def synhronize

    end
  end
end
