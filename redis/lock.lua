-- redis.replicate_commands();

local exists_key    = KEYS[1]
local grabbed_key   = KEYS[2]
local available_key = KEYS[3]
local unique_keys   = KEYS[4]
local unique_digest = KEYS[5]

local job_id = ARGV[1]
local ttl    = tonumber(ARGV[2])
local lock   = ARGV[3]

local function current_time()
  local time = redis.call('time')
  local s = time[1]
  local ms = time[2]
  local number = tonumber((s .. '.' .. ms))

  return number
end

local stored_token = redis.call('GET', exists_key)
if stored_token and stored_token ~= job_id then
  return stored_token
end

redis.call('SET', exists_key, job_id)

----------------------------------------------------------------
-- TODO: Legacy support (Remove in v6.1)
local old_token  = redis.call('GET', unique_digest)
if old_token then
  if old_token == job_id or old_token == '2' then
    -- No need to return, we just delete the old key
    redis.call('DEL', unique_digest)
  else
    return old_token
  end
end
----------------------------------------------------------------

redis.call('SADD', unique_keys, unique_digest)
redis.call('DEL', grabbed_key)
-- TODO: Move this to LUA when redis 3.2 is the least supported
-- redis.call('HSET', grabbed_key, job_id, current_time())
---------------------------------------------------------------
redis.call('DEL', available_key)
redis.call('RPUSH', available_key, job_id)

-- The client should only set ttl for until_expired
-- The server should set ttl for all other jobs
if lock == "until_expired" and ttl then
  -- We can't keep the key here because it will otherwise never be deleted
  redis.call('SREM', unique_keys, unique_digest)

  redis.call('EXPIRE', available_key, ttl)
  redis.call('EXPIRE', exists_key, ttl)
  redis.call('EXPIRE', unique_digest, ttl)
end

return job_id
