-------- BEGIN keys ---------
local locked  = KEYS[1]
local digests = KEYS[2]
-------- END keys ---------


-------- BEGIN lock arguments ---------
local job_id    = ARGV[1]
local lock_type = ARGV[2]
-------- END lock arguments -----------


--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[3])
local debug_lua    = tostring(ARGV[4]) == "1"
local max_history  = tonumber(ARGV[5])
local script_name  = tostring(ARGV[6]) .. ".lua"
local redisversion = ARGV[7]
---------  END injected arguments ---------


--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------


---------  BEGIN unlock_v9.lua ---------
log_debug("BEGIN unlock_v9 locked:", locked, "job_id:", job_id)

-- For until_expired: don't remove from LOCKED hash (TTL handles expiry)
if lock_type == "until_expired" then
  log_debug("until_expired: skipping HDEL, TTL will handle expiry")
  log_debug("END unlock_v9")
  return job_id
end

-- Check if this job actually holds the lock
local holds_lock = redis.call("HEXISTS", locked, job_id) == 1
if not holds_lock then
  -- Job doesn't hold the lock — could be already unlocked or orphaned
  -- Check if the hash is completely empty (orphaned lock scenario)
  local locked_count = redis.call("HLEN", locked)
  if locked_count == 0 then
    -- Orphaned: clean up the digest entry
    local digest = string.gsub(locked, ":LOCKED$", "")
    log_debug("Orphaned lock, cleaning up digest:", digest)
    redis.call("ZREM", digests, digest)
    return job_id
  end
  log_debug("Job does not hold lock, skipping")
  return nil
end

-- Remove this job from the lock
log_debug("HDEL", locked, job_id)
redis.call("HDEL", locked, job_id)

-- If no more holders, remove from digests tracking
local remaining = redis.call("HLEN", locked)
if remaining == 0 then
  local digest = string.gsub(locked, ":LOCKED$", "")
  log_debug("No more holders, ZREM", digests, digest)
  redis.call("ZREM", digests, digest)
  redis.call("UNLINK", locked)
end

log_debug("END unlock_v9 locked:", locked, "job_id:", job_id)
return job_id
----------  END unlock_v9.lua ----------
