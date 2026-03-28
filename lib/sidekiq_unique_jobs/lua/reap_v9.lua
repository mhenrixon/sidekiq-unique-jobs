-------- BEGIN keys ---------
local digests = KEYS[1]
-------- END keys ---------


-------- BEGIN reap arguments ---------
local reaper_count = tonumber(ARGV[1])
-------- END reap arguments -----------


--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[2])
local debug_lua    = tostring(ARGV[3]) == "1"
local max_history  = tonumber(ARGV[4])
local script_name  = tostring(ARGV[5]) .. ".lua"
local redisversion = ARGV[6]
---------  END injected arguments ---------


--------  BEGIN local functions --------
<%= include_partial "shared/_common_v9.lua" %>
----------  END local functions ----------


---------  BEGIN reap_v9.lua ---------
-- v9 reaper: simply scan digests ZSET and remove entries
-- whose LOCKED hash no longer exists (expired via TTL or crashed).
-- This is O(n) in the number of digests but each check is O(1).

log_debug("BEGIN reap_v9")

local del_count = 0
local cursor = "0"

repeat
  local result = redis.call("ZSCAN", digests, cursor, "COUNT", 50)
  cursor = result[1]
  local entries = result[2]

  for i = 1, #entries, 2 do
    local digest = entries[i]
    local locked = digest .. ":LOCKED"

    if redis.call("EXISTS", locked) == 0 then
      log_debug("Stale digest:", digest, "- LOCKED hash gone, removing from ZSET")
      redis.call("ZREM", digests, digest)
      del_count = del_count + 1

      if del_count >= reaper_count then
        log_debug("Reached reaper_count limit:", reaper_count)
        return del_count
      end
    end
  end
until cursor == "0"

log_debug("END reap_v9: removed", del_count, "stale digests")
return del_count
----------  END reap_v9.lua ----------
