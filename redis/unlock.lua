local unique_digest = KEYS[1] -- TODO: Legacy support (Remove in v6.1)
local exists_key    = KEYS[2]
local grabbed_key   = KEYS[3]
local available_key = KEYS[4]
local version_key   = KEYS[5]
local unique_set    = KEYS[6]

local job_id    = ARGV[1]
local ttl       = tonumber(ARGV[2])
local lock_type = ARGV[3]

-- BEGIN check if we own the lock
redis.log(redis.LOG_DEBUG, "unlock.lua - Check if owning the lock")

local stored_jid = redis.call('GET', unique_digest)

if stored_jid and stored_jid ~= job_id then
  redis.log(redis.LOG_DEBUG, "unlock.lua - Locked locked by the another job_id: " .. stored_jid .. ". returning it" )
  return stored_jid
else
  redis.log(redis.LOG_DEBUG, "unlock.lua - Locked by the current job_id: " .. job_id )
end

local old_jid    = redis.call('GET', exists_key)
if old_jid and old_jid ~= job_id then
  redis.log(redis.LOG_DEBUG, "unlock.lua - Locked by another job_id. Converting lock and returning job_id: " .. old_jid )
  redis.call('DEL', unique_set)   -- TODO: Legacy support (Remove in v6.1)
  redis.call('DEL', available_key) -- TODO: Legacy support (Remove in v6.1)
  redis.call('DEL', grabbed_key)   -- TODO: Legacy support (Remove in v6.1)
  redis.call('DEL', exists_key)    -- TODO: Legacy support (Remove in v6.1)
  redis.call('DEL', version_key)   -- TODO: Legacy support (Remove in v6.1)
  redis.call('DEL', 'uniquejobs')  -- TODO: Legacy support (Remove in v6.1)

  redis.call('SET', unique_digest, old_jid)

  return old_jid
else
  redis.log(redis.LOG_DEBUG, "unlock.lua - Locked by the current job_id: " .. job_id )
end
-- END check if we own the lock


-- BEGIN deleting lock
redis.log(redis.LOG_DEBUG, "unlock.lua - Removing digest: " .. unique_digest .. " from: " .. unique_set)

redis.call('SREM', unique_set, unique_digest)
redis.call('DEL', available_key) -- TODO: Legacy support (Remove in v6.1)
redis.call('DEL', grabbed_key)   -- TODO: Legacy support (Remove in v6.1)
redis.call('DEL', exists_key)    -- TODO: Legacy support (Remove in v6.1)
redis.call('DEL', version_key)   -- TODO: Legacy support (Remove in v6.1)
redis.call('DEL', 'uniquejobs')  -- TODO: Legacy support (Remove in v6.1)

if ttl and ttl > 0 then
  redis.log(redis.LOG_DEBUG, "unlock.lua - Expiring keys in: " .. ttl)
  redis.call('PEXPIRE', unique_digest, ttl)
else
  redis.log(redis.LOG_DEBUG, "unlock.lua - No expiration, deleting digest immediately")
  redis.call('DEL', unique_digest)
end

return job_id
-- END deleting lock
