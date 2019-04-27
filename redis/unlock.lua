local exists_key    = KEYS[1]
local grabbed_key   = KEYS[2]
local available_key = KEYS[3]
local version_key   = KEYS[4]
local unique_keys   = KEYS[5]
local unique_digest = KEYS[6] -- TODO: Legacy support (Remove in v6.1)

local job_id    = ARGV[1]
local ttl       = tonumber(ARGV[2])
local lock_type = ARGV[3]

-- redis.log(redis.LOG_DEBUG, "unlock.lua - Check if owning the lock")
-- local stored_jid = redis.call('GET', exists_key)
-- if stored_jid and stored_jid ~= job_id then
--   redis.log(redis.LOG_DEBUG, "unlock.lua - Locked locked by the another job_id: " .. stored_jid .. ". returning it" )
--   return stored_jid
-- else
--   redis.log(redis.LOG_DEBUG, "unlock.lua - Locked by the current job_id: " .. job_id )
-- end

redis.log(redis.LOG_DEBUG, "unlock.lua - Removing digest: " .. unique_digest .. " from: " .. unique_keys)

redis.call('SREM', unique_keys, unique_digest)
redis.call('DEL', grabbed_key)
redis.call('DEL', unique_digest)  -- TODO: Legacy support (Remove in v6.1)
redis.call('DEL', 'uniquejobs')   -- TODO: Old job hash, just drop the darn thing  (Remove in v6.1)

if ttl and ttl > 0 then
  redis.log(redis.LOG_DEBUG, "unlock.lua - Expiring keys in: " .. ttl)
  redis.call('EXPIRE', exists_key, ttl)
  redis.call('DEL', version_key, ttl)      -- TODO: Legacy support (Remove in v6.1)
else
  redis.log(redis.LOG_DEBUG, "unlock.lua - No expiration, deleting keys immediately")
  redis.call('DEL', exists_key)
  redis.call('DEL', version_key)    -- TODO: Legacy support (Remove in v6.1)
end

redis.log(redis.LOG_DEBUG, "unlock.lua - Pushing available key: " .. available_key .. " ready for the next job")
local count = redis.call('LPUSH', available_key, job_id)
redis.call('EXPIRE', available_key, 5)
return count

