module LockSimulator
  def self.create_v6_locks(num = 20)
    old_digests = Array.new(num) { |n| "uniquejobs:digest-#{n}" }
    Sidekiq.redis do |conn|
      old_digests.each_slice(100) do |chunk|
        conn.pipelined do
          chunk.each do |digest|
            job_id = SecureRandom.hex(12)
            conn.sadd("unique:keys", digest)
            conn.set("#{digest}:EXISTS", job_id)
            conn.rpush("#{digest}:AVAILABLE", digest)
            conn.hset("#{digest}:GRABBED", job_id, Time.now.to_f)
          end
        end
      end
    end
  end
end
