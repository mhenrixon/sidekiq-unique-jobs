local lock_key  = KEYS[1]
local free_list = KEYS[2]
local held_list = KEYS[3]
local free_zet  = KEYS[4]
local held_zet  = KEYS[5]
local lock_hash = KEYS[6]

local job_id       = ARGV[1]
local ttl          = tonumber(ARGV[2])
local lock_type    = ARGV[3]
local current_time = tonumber(ARGV[4])
local concurrency  = tonumber(ARGV[5])

-- BEGIN lock
redis.log(redis.LOG_DEBUG, "create.lua - BEGIN create for key: " .. lock_key .. " with job_id: " .. job_id)

local prev_jid = redis.call('GETSET', lock_key, job_id)
if not prev_jid then
  redis.log(redis.LOG_DEBUG, "create.lua - Lock key: " .. lock_key .. " created for job_id: " .. job_id)
elseif prev_jid == job_id then
  redis.log(redis.LOG_DEBUG, "create.lua - Lock key: " .. lock_key .. " existed for job_id: " .. job_id)
  return job_id
else
  redis.log(redis.LOG_DEBUG, "create.lua - Lock key: " .. lock_key .. " updated for job_id: " .. prev_jid)
  return prev_jid
end

if redis.call('HLEN', lock_hash) >= concurrency then
  redis.log(redis.LOG_DEBUG, "create.lua - Lock hash: " .. lock_hash .. " limited")
end

if redis.call('HEXISTS', lock_hash, job_id) ~= 0 then
  redis.log(redis.LOG_DEBUG, "create.lua - Lock hash: " .. lock_hash .. " existed for job_id: " .. job_id)
  return job_id
end

-- The Sidekiq client should only set ttl for until_expired
-- The Sidekiq server should set ttl for all other jobs
if lock_type == "until_expired" and ttl > 0 then
  redis.log(redis.LOG_DEBUG, "create.lua - Expiring " .. lock_key .. " in " .. tostring(ttl) .. "ms")
  redis.call('PEXPIRE', lock_key, ttl)
end

local exist_count = redis.call('ZCARD', free_zet)
if exist_count < concurrency then
  redis.log(redis.LOG_DEBUG, "create.lua - ZADD " .. free_zet .. " " .. tostring(current_time) .. " " .. job_id)
  redis.call('ZADD', free_zet, current_time, job_id)
else
  redis.log(redis.LOG_DEBUG, "create.lua - Skipping ZADD (" .. free_zet .. " concurrency: " .. tostring(concurrency) .. ", exist_count: " .. tostring(exist_count) .. ")")
end

local exist_count = redis.call('LLEN', free_list)
if exist_count == nil or exist_count < concurrency then
  redis.log(redis.LOG_DEBUG, "create.lua - LPUSH " .. free_list .. " " .. tostring(current_time) .. " " .. job_id)
  redis.call('LPUSH', free_list, lock_key)
end

redis.log(redis.LOG_DEBUG, "create.lua - END create for key: " .. lock_key .. " with job_id: " .. job_id)
return job_id
  -- END lock
