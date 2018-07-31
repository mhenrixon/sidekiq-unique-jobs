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

local stored_token  = redis.call('GETSET', exists_key, job_id)
if stored_token then
  return stored_token
end

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
redis.call('EXPIRE', exists_key, 5)
redis.call('DEL', grabbed_key)
redis.call('DEL', available_key)

if concurrency and concurrency > 1 then
  for index = 1, concurrency do
    redis.call('RPUSH', available_key, index)
  end
else
  redis.call('RPUSH', available_key, job_id)
end
redis.call('GETSET', version_key, api_version)
redis.call('PERSIST', exists_key)

return job_id
