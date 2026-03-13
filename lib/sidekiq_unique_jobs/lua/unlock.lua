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


-------- BEGIN unlock-specific arguments ---------
-- sync_locked flag: when present (ARGV has 11 elements), shifts injected args by 1
local has_sync_flag = #ARGV > 10
local sync_locked   = has_sync_flag and tonumber(ARGV[6]) == 1
local arg_offset    = has_sync_flag and 1 or 0
-------- END unlock-specific arguments -----------


--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[6 + arg_offset])
local debug_lua    = tostring(ARGV[7 + arg_offset]) == "1"
local max_history  = tonumber(ARGV[8 + arg_offset])
local script_name  = tostring(ARGV[9 + arg_offset]) .. ".lua"
local redisversion = ARGV[10 + arg_offset]
---------  END injected arguments ---------


--------  BEGIN Variables --------
-- Defer LLEN/HLEN calls to where they're needed to avoid unnecessary commands
---------  END Variables ---------


--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------


---------  Begin unlock.lua ---------
log_debug("BEGIN unlock digest:", digest, "(job_id: " .. job_id ..")")

-- Fast path for sync-locked single locks:
-- We know the job holds the lock (acquired atomically via queue_and_lock.lua)
-- No queued/primed lists exist, no BLMOVE waiters, no sentinel needed.
-- Just: HDEL + UNLINK + ZREM = 3 commands
if sync_locked and limit <= 1 and lock_type ~= "until_expired" then
  log_debug("HDEL", locked, job_id)
  redis.call("HDEL", locked, job_id)
  log_debug("UNLINK", digest, info, locked, primed)
  redis.call("UNLINK", digest, info, locked, primed)
  log_debug("ZREM", digests, digest)
  redis.call("ZREM", digests, digest)
  log("Unlocked")
  log_debug("END unlock digest:", digest, "(job_id: " .. job_id ..")")
  return job_id
end

-- Standard path: check if this job actually holds the lock
local holds_lock = redis.call("HEXISTS", locked, job_id) == 1

-- Clean up queued/primed entries only if not holding the lock
-- (when holding the lock, lock.lua already UNLINKed both lists)
if not holds_lock then
  redis.call("LREM", queued, -1, job_id)
  redis.call("LREM", primed, -1, job_id)
end
log_debug("HEXISTS", locked, job_id, "=>", holds_lock)

if not holds_lock then
  -- Job doesn't hold the lock - check if this is an orphaned lock scenario
  local queued_count = redis.call("LLEN", queued)
  local primed_count = redis.call("LLEN", primed)
  local locked_count = redis.call("HLEN", locked)
  if queued_count == 0 and primed_count == 0 and locked_count == 0 then
    log_debug("Orphaned lock - cleaning up")
    -- Continue with cleanup below
  else
    -- Other jobs still hold locks for this digest
    log("Yielding to other lock holders")
    log_debug("Yielding to other lock holders for", digest, "by job", job_id)
    -- Return nil to indicate this job did not hold the lock
    return nil
  end
end

if lock_type ~= "until_expired" then
  log_debug("HDEL", locked, job_id)
  redis.call("HDEL", locked, job_id)

  if limit and limit > 1 then
    -- Multi-lock: need to check if others remain
    local locked_count = redis.call("HLEN", locked)

    log_debug("UNLINK", digest, info)
    redis.call("UNLINK", digest, info)

    if locked_count < 1 then
      log_debug("UNLINK", locked, primed)
      redis.call("UNLINK", locked, primed)
      log_debug("ZREM", digests, digest)
      redis.call("ZREM", digests, digest)
    elseif redis.call("LLEN", primed) == 0 then
      log_debug("UNLINK", primed)
      redis.call("UNLINK", primed)
    end
  else
    -- Single-lock (limit <= 1): after HDEL, no locks remain.
    -- Clean up everything in one batch without checking HLEN.
    log_debug("UNLINK", digest, info, locked, primed)
    redis.call("UNLINK", digest, info, locked, primed)
    log_debug("ZREM", digests, digest)
    redis.call("ZREM", digests, digest)
  end
else
  -- until_expired: don't HDEL, but still remove from digests tracking
  log_debug("ZREM", digests, digest)
  redis.call("ZREM", digests, digest)
end

-- Push sentinel to unblock any waiting BLMOVE
log_debug("LPUSH", queued, "1")
redis.call("LPUSH", queued, "1")

log_debug("PEXPIRE", queued, 5000)
redis.call("PEXPIRE", queued, 5000)

log("Unlocked")
log_debug("END unlock digest:", digest, "(job_id: " .. job_id ..")")
return job_id
---------  END unlock.lua ---------
