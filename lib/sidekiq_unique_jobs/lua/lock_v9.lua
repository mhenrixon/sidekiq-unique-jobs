-------- BEGIN keys ---------
local locked  = KEYS[1]
local digests = KEYS[2]
-------- END keys ---------


-------- BEGIN lock arguments ---------
local job_id    = ARGV[1]
local pttl      = tonumber(ARGV[2])
local lock_type = ARGV[3]
local limit     = tonumber(ARGV[4])
local metadata  = ARGV[5]
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


---------  BEGIN lock_v9.lua ---------
log_debug("BEGIN lock_v9 locked:", locked, "job_id:", job_id)

-- Check if this job already holds the lock (idempotent re-lock)
if redis.call("HEXISTS", locked, job_id) == 1 then
  log_debug("Already locked by job_id:", job_id)
  return job_id
end

-- Check limit
local locked_count = redis.call("HLEN", locked)
if locked_count >= limit then
  log_debug("Limit exceeded:", locked_count, "of", limit)
  return nil
end

-- Acquire the lock: store metadata (JSON with timestamp, lock_type, worker)
log_debug("HSET", locked, job_id, metadata)
redis.call("HSET", locked, job_id, metadata)

-- Track in digests sorted set
-- For until_expired: score = expiry time (current_time + pttl)
-- For everything else: score = current_time
local score
if lock_type == "until_expired" and pttl and pttl > 0 then
  score = current_time + pttl
else
  score = current_time
end
log_debug("ZADD", digests, score, string.gsub(locked, ":LOCKED$", ""))
redis.call("ZADD", digests, score, string.gsub(locked, ":LOCKED$", ""))

-- Set TTL if specified
if pttl and pttl > 0 then
  log_debug("PEXPIRE", locked, pttl)
  redis.call("PEXPIRE", locked, pttl)
end

log_debug("END lock_v9 locked:", locked, "job_id:", job_id)
return job_id
----------  END lock_v9.lua ----------
