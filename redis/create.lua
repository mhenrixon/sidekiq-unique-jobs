-- redis.replicate_commands();

local exists_key    = KEYS[1]
local grabbed_key   = KEYS[2]
local available_key = KEYS[3]
local version_key   = KEYS[4]
local unique_digest = KEYS[5]

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
stored_token  = redis.call('GET', unique_digest)
if stored_token then
  if not stored_token == job_id and not stored_token == '2' then
    return stored_token
  end
end
----------------------------------------------------------------

redis.call('EXPIRE', exists_key, 10)
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

if expiration then
  redis.call('EXPIRE', available_key, expiration)
  redis.call('EXPIRE', exists_key, expiration)
  redis.call('EXPIRE', version_key, expiration)
end

return job_id
