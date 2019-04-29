local unique_digest = KEYS[1]
local waiting_set   = KEYS[2]

local job_id       = ARGV[1]
local ttl          = tonumber(ARGV[2])
local lock_type    = ARGV[3]
local current_time = tonumber(ARGV[4])

-- BEGIN lock
redis.log(redis.LOG_DEBUG, "lock.lua - Locking job_id: " .. job_id .. " with digest: " .. unique_digest)
if redis.call('SET', unique_digest, job_id, 'NX') then
  -- The Sidekiq client should only set ttl for until_expired
  -- The Sidekiq server should set ttl for all other jobs
  if lock_type == "until_expired" and ttl > 0 then
    redis.log(redis.LOG_DEBUG, "lock.lua - Expiring " .. unique_digest .. " in " .. tostring(ttl) .. "ms")
    redis.call('PEXPIRE', unique_digest, ttl)
  else
    redis.call('ZADD', waiting_set, current_time, unique_digest)
  end

  return job_id
else
  return redis.call('GET', unique_digest)
end
  -- END lock
