-------- BEGIN keys ---------
local working = KEYS[1]
local locked  = KEYS[2]
local digests = KEYS[3]
-------- END keys ---------


-------- BEGIN ack arguments ---------
local job       = ARGV[1]
local jid       = ARGV[2]
local digest    = ARGV[3]
local lock_type = ARGV[4]
-------- END ack arguments -----------


--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[5])
local debug_lua    = tostring(ARGV[6]) == "1"
local max_history  = tonumber(ARGV[7])
local script_name  = tostring(ARGV[8]) .. ".lua"
local redisversion = ARGV[9]
---------  END injected arguments ---------


--------  BEGIN local functions --------
<%= include_partial "shared/_common_v9.lua" %>
----------  END local functions ----------


---------  BEGIN ack.lua ---------
log_debug("BEGIN ack working:", working, "jid:", jid, "lock_type:", lock_type)

-- 1. Remove from working list (always, regardless of lock type)
local removed = redis.call("LREM", working, 1, job)
log_debug("LREM working:", removed)

-- 2. Unlock based on lock_type
if not digest or digest == "" then
  -- Not a unique job, nothing to unlock
  log_debug("Not a unique job, skipping unlock")
  return 1
end

if lock_type == "until_expired" then
  -- until_expired: don't unlock, TTL handles expiry
  log_debug("until_expired: keeping lock, TTL will handle expiry")
  return 1
end

if lock_type == "while_executing" or lock_type == "until_and_while_executing" then
  -- These lock types manage their own unlock in the server middleware
  -- The "while" phase lock is released by the middleware's ensure block
  log_debug(lock_type, ": middleware manages unlock")
  return 1
end

-- For until_executed, until_executing: release the lock
local holds_lock = redis.call("HEXISTS", locked, jid)
if holds_lock == 1 then
  log_debug("HDEL", locked, jid)
  redis.call("HDEL", locked, jid)

  local remaining = redis.call("HLEN", locked)
  if remaining == 0 then
    log_debug("No more holders, ZREM + UNLINK")
    redis.call("ZREM", digests, digest)
    redis.call("UNLINK", locked)
  end
end

log_debug("END ack jid:", jid)
return 1
----------  END ack.lua ----------
