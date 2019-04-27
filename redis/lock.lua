-- redis.replicate_commands();

local exists_key    = KEYS[1]
local available_key = KEYS[2]
local unique_keys   = KEYS[3]
local unique_digest = KEYS[4]

local job_id    = ARGV[1]
local ttl       = tonumber(ARGV[2])
local lock_type = ARGV[3]

redis.log(redis.LOG_DEBUG, "lock.lua - Check for: " .. job_id .. " if can lock")

local stored_jid = redis.call('GET', exists_key)

if not stored_jid or stored_jid == false then
  redis.log(redis.LOG_DEBUG, "lock.lua - No existing locks for: " .. exists_key)
elseif stored_jid == job_id then
  redis.log(redis.LOG_DEBUG, "lock.lua - Lock owned by current job_id: " .. job_id)
else
  redis.log(redis.LOG_DEBUG, "lock.lua - Lock owned by another job_id: " .. stored_jid)
  return stored_jid
end

----------------------------------------------------------------
-- TODO: Legacy support (Remove in v6.1)
redis.log(redis.LOG_DEBUG, "lock.lua - Check for legacy lock")

local old_jid    = redis.call('GET', unique_digest)

if not old_jid or old_jid == false then
  redis.log(redis.LOG_DEBUG, "lock.lua - No existing legacy lock for:" .. exists_key)
elseif old_jid == job_id or old_jid == '2'  then
  redis.log(redis.LOG_DEBUG, "lock.lua - Converting legacy lock for current job_id: " .. job_id)
  redis.call('DEL', unique_digest)
else
  redis.log(redis.LOG_DEBUG, "lock.lua - Existing legacy lock for another job_id: " .. old_jid)
  return old_jid
end

redis.log(redis.LOG_DEBUG, "lock.lua - Creating necessary lock keys")

redis.call('SET', exists_key, job_id)
redis.call('SADD', unique_keys, unique_digest)

-- The client should only set ttl for until_expired
-- The server should set ttl for all other jobs
if lock_type == "until_expired" and ttl then
  redis.log(redis.LOG_DEBUG, "lock.lua - Until expired job. Setting ttl on all keys")
  -- We can't keep the key here because it will otherwise never be deleted
  redis.call('SREM', unique_keys, unique_digest)

  redis.call('EXPIRE', available_key, ttl)
  redis.call('EXPIRE', exists_key, ttl)
  redis.call('EXPIRE', unique_digest, ttl)
end

redis.call('DEL', available_key)
redis.call('RPUSH', available_key, job_id)

return job_id
