module SidekiqUniqueJobs
  module Client
    module Extensions
      def lock_queue_script
        <<-LUA
          local ret = redis.call('GET', KEYS[1])
          if not ret or string.sub(ret, 1, 9) == 'scheduled' then
            return redis.call('SETEX', KEYS[1], ARGV[1], ARGV[2])
          end
        LUA
      end
    end
  end
end
