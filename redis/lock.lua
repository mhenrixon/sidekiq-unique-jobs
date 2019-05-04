local digest    = KEYS[1]
local queued    = KEYS[2]
local primed    = KEYS[3]
local locked    = KEYS[4]
local changelog = KEYS[5]

local job_id       = ARGV[1]
local primed_jid   = ARGV[2]           -- The job_id that was previously primed
local pttl         = tonumber(ARGV[3])
local lock_type    = ARGV[4]
local current_time = tonumber(ARGV[5])
local limit        = tonumber(ARGV[6])

local locked_count = redis.call('HLEN', locked)
local within_limit = limit > locked_count
local limit_exceeded = not within_limit
local verbose = true
local track   = true

local function log_debug( ... )
  if verbose == false then return end
  local result = ""
  for i,v in ipairs(arg) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, "lock.lua -" ..  result)
end

local function log(message, prev_jid)
  if track == false then return end
  local entry = cjson.encode({digest = digest, job_id = job_id, script = "lock.lua", message = message, time = current_time, prev_jid = prev_jid, primed_jid = primed_jid })

  redis.call('ZADD', changelog, current_time, entry);
  redis.call('ZREMRANGEBYSCORE', changelog, '-inf', math.floor(current_time) - 86400000);
  redis.call('PUBLISH', changelog, entry);
end

-- BEGIN lock
log_debug("BEGIN lock digest:", digest, "job_id:", job_id, ", primed_jid:", primed_jid)

if limit_exceeded then
  log_debug("Limit exceeded:", digest, "(",  locked_count, "of", limit, ")")
  log("Limit exceeded", digest, job_id, current_time)
  return nil
end

if redis.call('HEXISTS', locked, job_id) == 1 then
  log_debug(locked, "already locked with job_id:", job_id)
  log("Already locked", digest, job_id, current_time)
  return job_id
end

-- TODO: Verify that we can still obtain the lock

log_debug("HSET", locked, job_id, current_time)
redis.call('HSET', locked, job_id, current_time)

log_debug("LREM", primed, 1, job_id)
redis.call('LREM', primed, 1, job_id)

-- The Sidekiq client should only set pttl for until_expired
-- The Sidekiq server should set pttl for all other jobs
if lock_type == 'until_expired' and pttl and pttl > 0 then
  log_debug("PEXPIRE", digest, pttl)
  redis.call('PEXPIRE', digest, pttl)

  log_debug("PEXPIRE", queued, pttl)
  redis.call('PEXPIRE', queued, pttl)

  log_debug("PEXPIRE", primed, pttl)
  redis.call('PEXPIRE', primed, pttl)

  log_debug("PEXPIRE", locked, pttl)
  redis.call('PEXPIRE', locked, pttl)
end

log("Locked")
log_debug("END lock digest:", digest, "job_id:", job_id, ", primed_jid:", primed_jid)
return job_id
  -- END lock
