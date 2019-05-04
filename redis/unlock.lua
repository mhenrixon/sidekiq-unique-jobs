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

local queued_count = redis.call('LLEN', queued)
local primed_count = redis.call('LLEN', primed)
local locked_count = redis.call('HLEN', locked)
local verbose = true
local track   = true

local function log_debug( ... )
  if verbose == false then return end
  local result = ""
  for i,v in ipairs(arg) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, "unlock.lua -" ..  result)
end

local function log(message, prev_jid)
  if track == false then return end
  local entry = cjson.encode({digest = digest, job_id = job_id, script = "unlock.lua", message = message, time = current_time, prev_jid = prev_jid })

  redis.call('ZADD', changelog, current_time, entry);
  redis.call('ZREMRANGEBYSCORE', changelog, '-inf', math.floor(current_time) - 86400000);
  redis.call('PUBLISH', changelog, entry);
end

-- BEGIN unlock
log_debug("BEGIN unlock with key:", digest, "for job:", job_id)

log_debug("HEXISTS", locked, job_id)
if redis.call('HEXISTS', locked, job_id) == 0 then
  -- TODO: Improve orphaned lock detection
  if queued_count == 0 and primed_count == 0 and locked_count == 0 then
    log_debug("Orphaned lock", digest, "for job", job_id)
  else
    local result = ''
    for i,v in ipairs(redis.call("HKEYS", locked)) do
      result = result .. v .. ','
    end
    result = locked .. ' (' .. result .. ')'
    log("Yielding to: " .. result)
    log_debug("Yielding to", result, locked, "by job", job_id)
    return nil
  end
end

log_debug("LREM", queued, -1, job_id)
redis.call('LREM', queued, -1, job_id)

log_debug("LREM", primed, -1, job_id)
redis.call('LREM', primed, -1, job_id)

if ttl and ttl > 0 then
  log_debug("PEXPIRE", digest, ttl)
  redis.call('PEXPIRE', digest, ttl)

  log_debug("PEXPIRE", queued, ttl)
  redis.call('PEXPIRE', queued, ttl)

  log_debug("PEXPIRE", primed, ttl)
  redis.call('PEXPIRE', primed, ttl)

  log_debug("PEXPIRE", locked, ttl)
  redis.call('PEXPIRE', locked, ttl)
else
  log_debug('DEL', digest)
  redis.call('DEL', digest)

  log_debug("PEXPIRE", queued, 10)
  redis.call('LPUSH', queued, "1")
  redis.call('PEXPIRE', queued, 10)

  log_debug("PEXPIRE", primed, 10)
  redis.call('PEXPIRE', primed, 10)

  log_debug("HDEL", locked, job_id)
  redis.call("HDEL", locked, job_id)
end

log("Unlocked")
log_debug("END unlock digest:", digest, "(job_id: " .. job_id ..")")
return job_id
