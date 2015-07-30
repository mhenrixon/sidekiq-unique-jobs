module SidekiqUniqueJobs
  module Server
    module Extensions
      def remove_on_match
        <<-LUA
          if redis.call('GET', KEYS[1]) == ARGV[1] then
            redis.call('DEL', KEYS[1])
          end
        LUA
      end
    end
  end
end
