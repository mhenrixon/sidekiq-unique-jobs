-------- BEGIN keys ---------
local digest           = KEYS[1]
local queued           = KEYS[2]
local primed           = KEYS[3]
local locked           = KEYS[4]
local info             = KEYS[5]
local changelog        = KEYS[6]
local digests          = KEYS[7]
local expiring_digests = KEYS[8]
-------- END keys ---------


-------- BEGIN lock arguments ---------
local job_id       = ARGV[1]
local pttl         = tonumber(ARGV[2])
local lock_type    = ARGV[3]
local limit        = tonumber(ARGV[4])
local lock_score   = ARGV[5]
-------- END lock arguments -----------


--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[6])
local debug_lua    = tostring(ARGV[7]) == "1"
local max_history  = tonumber(ARGV[8])
local script_name  = tostring(ARGV[9]) .. ".lua"
local redisversion = ARGV[10]
---------  END injected arguments ---------


--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------


---------  BEGIN queue_and_lock.lua ---------
-- Combined queue + lock script for non-blocking lock acquisition.
-- Eliminates the LMOVE between separate queue/lock scripts and
-- removes duplicate HEXISTS checks.

log_debug("BEGIN queue_and_lock digest:", digest, "job_id:", job_id)

if limit <= 1 then
  -- Single-lock fast path: use HLEN to detect both re-lock and contention
  -- in one command instead of HEXISTS + HLEN
  local locked_count = redis.call("HLEN", locked)
  if locked_count > 0 then
    -- Something is in the hash — check if it's us (re-lock) or someone else (contention)
    if redis.call("HEXISTS", locked, job_id) == 1 then
      log_debug(locked, "already locked with job_id:", job_id)
      log("Duplicate")
      return job_id
    else
      log_debug("Limit exceeded:", digest, "(", locked_count, "of", limit, ")")
      log("Limited")
      return nil
    end
  end

  -- locked_count == 0: no locks held, try to claim the digest
  local set_result = redis.call("SET", digest, job_id, "NX")
  if not set_result then
    local prev_jid = redis.call("GET", digest)
    if prev_jid == job_id then
      log_debug(digest, "already queued with job_id:", job_id)
      log("Duplicate")
      return job_id
    else
      -- For limit=1, if locked_count is 0 but digest exists with different job,
      -- this is a stale digest. Overwrite it.
      log_debug("Overwriting stale digest", prev_jid, "with", job_id)
      redis.call("SET", digest, job_id)
    end
  end
else
  -- Multi-lock path: original HEXISTS + limit checking
  if redis.call("HEXISTS", locked, job_id) == 1 then
    log_debug(locked, "already locked with job_id:", job_id)
    log("Duplicate")
    return job_id
  end

  local set_result = redis.call("SET", digest, job_id, "NX")
  if not set_result then
    local prev_jid = redis.call("GET", digest)
    if prev_jid == job_id then
      log_debug(digest, "already queued with job_id:", job_id)
      log("Duplicate")
      return job_id
    else
      local locked_count = redis.call("HLEN", locked)
      local queued_count = redis.call("LLEN", queued)
      if limit > locked_count and queued_count < limit then
        log_debug("Within limit, replacing", prev_jid, "with", job_id)
        redis.call("SET", digest, job_id)
      else
        log_debug("Limit exceeded:", digest)
        log("Limit exceeded", prev_jid)
        return nil
      end
    end
  end

  local locked_count = redis.call("HLEN", locked)
  if limit <= locked_count then
    log_debug("Limit exceeded:", digest, "(", locked_count, "of", limit, ")")
    log("Limited")
    return nil
  end
end

-- 4. Acquire the lock directly (skip LPUSH/LMOVE, go straight to HSET)
if lock_type == "until_expired" and pttl and pttl > 0 then
  log_debug("ZADD", expiring_digests, current_time + pttl, digest)
  redis.call("ZADD", expiring_digests, current_time + pttl, digest)
else
  local score
  if #lock_score == 0 then
    score = current_time
  else
    score = lock_score
  end
  log_debug("ZADD", digests, score, digest)
  redis.call("ZADD", digests, score, digest)
end

log_debug("HSET", locked, job_id, current_time)
redis.call("HSET", locked, job_id, current_time)

-- 5. Set TTL if specified
if pttl and pttl > 0 then
  log_debug("PEXPIRE", digest, pttl)
  redis.call("PEXPIRE", digest, pttl)

  log_debug("PEXPIRE", locked, pttl)
  redis.call("PEXPIRE", locked, pttl)

  log_debug("PEXPIRE", info, pttl)
  redis.call("PEXPIRE", info, pttl)
end

log("Locked")
log_debug("END queue_and_lock digest:", digest, "job_id:", job_id)
return job_id
----------  END queue_and_lock.lua ----------
