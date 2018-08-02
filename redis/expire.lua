-- redis.replicate_commands();

local exists_key    = KEYS[1]
local available_key = KEYS[2]
local version_key   = KEYS[3]

local expiration    = tonumber(ARGV[1])
local job_id        = ARGV[2]

if expiration then
  -- redis.log(redis.LOG_DEBUG, "expire.lua - expiring locks for job_id: " .. job_id)
  redis.call('EXPIRE', available_key, expiration)
  redis.call('EXPIRE', exists_key, expiration)
  redis.call('EXPIRE', version_key, expiration)
end
