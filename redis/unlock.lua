local unique_digest = KEYS[1]
local wait_key      = KEYS[2]
local work_key      = KEYS[3]
local version_key   = KEYS[4]
local unique_set    = KEYS[5]

local job_id       = ARGV[1]
local ttl          = tonumber(ARGV[2])
local lock_type    = ARGV[3]

-- BEGIN check if we own the lock
redis.log(redis.LOG_DEBUG, "unlock.lua - Check if owning the lock")

local stored_jid = redis.call('GET', unique_digest)

if stored_jid and stored_jid ~= job_id then
  redis.log(redis.LOG_DEBUG, "unlock.lua - Locked by another process job_id: " .. stored_jid)
  return
else
  redis.log(redis.LOG_DEBUG, "unlock.lua - Locked by the current job_id: " .. job_id )
end
-- END check if we own the lock

-- BEGIN unlock

redis.call('ZREM', unique_set, unique_digest)

if ttl and ttl > 0 then
  redis.log(redis.LOG_DEBUG, "unlock.lua - Expiring keys in: " .. ttl)
  redis.call('PEXPIRE', unique_digest, ttl)
  redis.call('ZREM', work_key, job_id)
  redis.call('PEXPIRE', work_key, ttl)
else
  redis.log(redis.LOG_DEBUG, "unlock.lua - No expiration, deleting digest immediately")
  redis.call('DEL', unique_digest)
  redis.call('ZREM', work_key, job_id)
  redis.call('PEXPIRE', work_key, 5)
end

return job_id
-- END unlock
