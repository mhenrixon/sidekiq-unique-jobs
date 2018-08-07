-- redis.replicate_commands();

local exists_key    = KEYS[1]
local grabbed_key   = KEYS[2]
local available_key = KEYS[3]
local version_key   = KEYS[4]
local unique_keys   = KEYS[5]
local unique_digest = KEYS[6]

local job_id        = ARGV[1]
local expiration    = tonumber(ARGV[2])
local api_version   = ARGV[3]
local concurrency   = tonumber(ARGV[4])

-- redis.log(redis.LOG_DEBUG, "create.lua - investigate possibility of locking jid: " .. job_id)

local stored_token  = redis.call('GET', exists_key)
if stored_token and stored_token ~= job_id then
  -- redis.log(redis.LOG_DEBUG, "create.lua - jid: " .. job_id .. " - returning existing jid: " .. stored_token)
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

-- redis.log(redis.LOG_DEBUG, "create.lua - creating locks for jid: " .. job_id)
redis.call('SADD', unique_keys, unique_digest)
redis.call('DEL', grabbed_key)
redis.call('DEL', available_key)

if concurrency and concurrency > 1 then
  for index = 1, concurrency do
    redis.call('RPUSH', available_key, index)
  end
else
  redis.call('RPUSH', available_key, job_id)
end
redis.call('SET', version_key, api_version)

if expiration then
  redis.call('EXPIRE', available_key, expiration)
  redis.call('EXPIRE', exists_key, expiration)
  redis.call('EXPIRE', grabbed_key, expiration)
  redis.call('EXPIRE', version_key, expiration)
end

return job_id
