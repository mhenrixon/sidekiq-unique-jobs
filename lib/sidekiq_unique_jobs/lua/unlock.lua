-------- BEGIN keys ---------
local digest    = KEYS[1]
local queued    = KEYS[2]
local primed    = KEYS[3]
local locked    = KEYS[4]
local info      = KEYS[5]
local changelog = KEYS[6]
local digests   = KEYS[7]
-------- END keys ---------


-------- BEGIN lock arguments ---------
local job_id     = ARGV[1]
local pttl       = tonumber(ARGV[2])
local lock_type  = ARGV[3]
local limit      = tonumber(ARGV[4])
local lock_score = ARGV[5]
-------- END lock arguments -----------


--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[6])
local debug_lua    = tostring(ARGV[7]) == "1"
local max_history  = tonumber(ARGV[8])
local script_name  = tostring(ARGV[9]) .. ".lua"
local redisversion = ARGV[10]
---------  END injected arguments ---------


--------  BEGIN Variables --------
local queued_count = redis.call("LLEN", queued)
local primed_count = redis.call("LLEN", primed)
local locked_count = redis.call("HLEN", locked)
---------  END Variables ---------


--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------


---------  Begin unlock.lua ---------
log_debug("BEGIN unlock digest:", digest, "(job_id: " .. job_id ..")")

log_debug("HEXISTS", locked, job_id)
if redis.call("HEXISTS", locked, job_id) == 0 then
  -- TODO: Improve orphaned lock detection
  if queued_count == 0 and primed_count == 0 and locked_count == 0 then
    log_debug("Orphaned lock")
  else
    local result = ""
    for i,v in ipairs(redis.call("HKEYS", locked)) do
      result = result .. v .. ","
    end
    result = locked .. " (" .. result .. ")"
    log("Yielding to: " .. result)
    log_debug("Yielding to", result, locked, "by job", job_id)
    return nil
  end
end

-- Just in case something went wrong
log_debug("LREM", queued, -1, job_id)
redis.call("LREM", queued, -1, job_id)

log_debug("LREM", primed, -1, job_id)
redis.call("LREM", primed, -1, job_id)

local redis_version = toversion(redisversion)

if lock_type ~= "until_expired" then
  log_debug("UNLINK", digest, info)
  redis.call("UNLINK", digest, info)

  log_debug("HDEL", locked, job_id)
  redis.call("HDEL", locked, job_id)
end

if redis.call("LLEN", primed) == 0 then
  log_debug("UNLINK", primed)
  redis.call("UNLINK", primed)
end

local locked_count = redis.call("HLEN", locked)

if locked_count < 1 then
  log_debug("UNLINK", locked)
  redis.call("UNLINK", locked)
end

if limit then
  if limit <= 1 and locked_count <= 1 then
    log_debug("ZREM", digests, digest)
    redis.call("ZREM", digests, digest)
  end
else
  if locked_count <= 1 then
    log_debug("ZREM", digests, digest)
    redis.call("ZREM", digests, digest)
  end
end

log_debug("LPUSH", queued, "1")
redis.call("LPUSH", queued, "1")

log_debug("PEXPIRE", queued, 5000)
redis.call("PEXPIRE", queued, 5000)

log("Unlocked")
log_debug("END unlock digest:", digest, "(job_id: " .. job_id ..")")
return job_id
---------  END unlock.lua ---------
