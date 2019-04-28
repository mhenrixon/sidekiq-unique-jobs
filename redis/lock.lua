-- redis.replicate_commands();

local unique_digest = KEYS[1]
local wait_key      = KEYS[2]
local work_key      = KEYS[3]
local exists_key    = KEYS[4]
local grabbed_key   = KEYS[5]
local available_key = KEYS[6]
local version_key   = KEYS[7]
local unique_set    = KEYS[8]

local job_id    = ARGV[1]
local ttl       = tonumber(ARGV[2])
local lock_type = ARGV[3]

redis.log(redis.LOG_DEBUG, "lock.lua - Check for: " .. job_id .. " if can lock")

-- BEGIN converting locks
local stored_jid = redis.call('GET', exists_key)

if not stored_jid or stored_jid == false then
  redis.log(redis.LOG_DEBUG, "lock.lua - No existing locks for: " .. unique_digest)
  redis.log(redis.LOG_DEBUG, "lock.lua - Lock is owned by current job_id: " .. job_id)
else
  redis.log(redis.LOG_DEBUG, "lock.lua - Early return because Lock is owned by another job_id: " .. stored_jid)
  redis.call('DEL', exists_key)    -- TODO: Legacy support (Remove in v6.1)
  redis.call('DEL', grabbed_key)   -- TODO: Legacy support (Remove in v6.1)
  redis.call('DEL', available_key) -- TODO: Legacy support (Remove in v6.1)
  redis.call('DEL', version_key)   -- TODO: Legacy support (Remove in v6.1)
  redis.call('DEL', 'uniquejobs')  -- TODO: Legacy support (Remove in v6.1)

  redis.call('SET', unique_digest, stored_jid)
  return stored_jid
end

----------------------------------------------------------------
-- TODO: Legacy support (Remove in v6.1)
redis.log(redis.LOG_DEBUG, "lock.lua - Check for legacy lock")

local old_jid = redis.call('GET', unique_digest)

if not old_jid or old_jid == false then
  redis.log(redis.LOG_DEBUG, "lock.lua - No existing legacy lock for:" .. unique_digest)
elseif old_jid == job_id or old_jid == '2'  then
  redis.log(redis.LOG_DEBUG, "lock.lua - Converting legacy lock for current job_id: " .. job_id)
else
  redis.log(redis.LOG_DEBUG, "lock.lua - Existing legacy lock for another job_id: " .. old_jid)
  return old_jid
end
----------------------------------------------------------------
-- END converting locks


-- BEGIN locking
redis.log(redis.LOG_DEBUG, "lock.lua - Creating necessary lock keys")
redis.call('SET', unique_digest, job_id)
redis.call('SADD', unique_set, unique_digest)

-- The Sidekiq client should only set ttl for until_expired
-- The Sidekiq server should set ttl for all other jobs
if lock_type == "until_expired" and ttl > 0 then
  redis.log(redis.LOG_DEBUG, "lock.lua - Until expired job, expiring " .. unique_digest .. " in " .. tostring(ttl) .. "ms")
  redis.call('SREM', unique_set, unique_digest)
  redis.call('PEXPIRE', unique_digest, ttl)
  redis.call('RPUSH', wait_key, job_id)
  redis.call('PEXPIRE', wait_key, ttl)
else
  redis.call('RPUSH', wait_key, job_id)
  redis.call('PEXPIRE', wait_key, 5)
end

return job_id

-- END locking
