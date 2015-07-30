module SidekiqUniqueJobs
  module Server
    module MockLib
      def unlock(lock_key, item)
        connection do |con|
          con.watch(lock_key)
          return con.unwatch unless con.get(lock_key) == item['jid']

          con.multi { con.del(lock_key) }
        end
      end
    end
  end
end
