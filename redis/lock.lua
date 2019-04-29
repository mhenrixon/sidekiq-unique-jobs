local unique_digest = KEYS[1]
local wait_key      = KEYS[2]
local work_key      = KEYS[3]
local version_key   = KEYS[4]
local unique_set    = KEYS[5]

local job_id       = ARGV[1]
local ttl          = tonumber(ARGV[2])
local lock_type    = ARGV[3]
local current_time = tonumber(ARGV[4])

-- BEGIN lock
if redis.call('SET', unique_digest, job_id, 'NX') then

  redis.log(redis.LOG_DEBUG, "lock.lua - Creating necessary lock keys")
  redis.call('ZADD', unique_set, current_time, unique_digest)

  -- The Sidekiq client should only set ttl for until_expired
  -- The Sidekiq server should set ttl for all other jobs
  if lock_type == "until_expired" and ttl > 0 then
    redis.log(redis.LOG_DEBUG, "lock.lua - Until expired job, expiring " .. unique_digest .. " in " .. tostring(ttl) .. "ms")
    redis.call('ZREM', unique_set, unique_digest)
    redis.call('PEXPIRE', unique_digest, ttl)
    redis.call('ZADD', wait_key, current_time, job_id)
    redis.call('PEXPIRE', wait_key, ttl)
  else
    redis.call('ZADD', wait_key, current_time, job_id)
    redis.call('PEXPIRE', wait_key, 5)
  end

  return job_id
end
  -- END lock
