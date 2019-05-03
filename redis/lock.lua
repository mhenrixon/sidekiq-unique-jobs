local digest    = KEYS[1]
local queued    = KEYS[2]
local primed    = KEYS[3]
local locked    = KEYS[4]
local changelog = KEYS[5]

local job_id       = ARGV[1]
local ttl          = tonumber(ARGV[2])
local lock_type    = ARGV[3]
local current_time = tonumber(ARGV[4])
local concurrency  = tonumber(ARGV[5])

local function log_debug( ... )
  local result = ""
  for i,v in ipairs(arg) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, "obtain.lua -" ..  result)
end


local function log(message, digest, job_id, time, prev_jid)

  local entry = cjson.encode({digest = digest, job_id = job_id, script = "obtain.lua", message = message, time = time, prev_jid = prev_jid })

  redis.call('ZADD', changelog, current_time, entry);
  redis.call('ZREMRANGEBYSCORE', changelog, '-inf', math.floor(current_time) - 86400000);
  redis.call('PUBLISH', changelog, entry);
end

-- BEGIN lock
log_debug("BEGIN lock for key:", digest, "with job_id:", job_id)

if redis.call('HEXISTS', locked, job_id) == 1 then
  log_debug(locked, "already locked with job_id:", job_id)
  log("Already locked", digest, job_id, current_time)
  return job_id
end

log_debug("HSET", locked, job_id, current_time)
redis.call('HSET', locked, job_id, current_time)

log_debug("LREM", primed, 1, digest)
redis.call('LREM', primed, 1, digest)

-- The Sidekiq client should only set ttl for until_expired
-- The Sidekiq server should set ttl for all other jobs
if lock_type ~= "until_expired" and ttl and ttl > 0 then
  log_debug("PEXPIRE", digest, ttl)
  redis.call('PEXPIRE', digest, ttl)
end

log_debug("END lock for key:", digest, "with job_id:", job_id)
return job_id
  -- END lock
