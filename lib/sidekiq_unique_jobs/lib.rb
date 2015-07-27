require 'pry-byebug'
module SidekiqUniqueServerLib
  def remove_if_matches
    <<-LUA
      if redis.call('GET', KEYS[1]) == ARGV[1] then
        redis.call('DEL', KEYS[1])
      end
    LUA
  end
end

module SidekiqUniqueServerMockLib
  def unlock(lock_key, item)
    connection do |con|
      con.watch(lock_key)
      if con.get(lock_key) == item['jid']
        ret = con.multi { con.del(lock_key) }
      else
        con.unwatch
      end
    end
  end
end
