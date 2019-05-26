-------- BEGIN keys ---------
local digest    = KEYS[1]
local queued    = KEYS[2]
local primed    = KEYS[3]
local locked    = KEYS[4]
local changelog = KEYS[5]
local digests   = KEYS[6]
-------- END keys ---------

-------- BEGIN lock arguments ---------
local job_id       = ARGV[1]
local pttl         = tonumber(ARGV[2])
local lock_type    = ARGV[3]
local limit        = tonumber(ARGV[4])
-------- END lock arguments -----------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[5])
local debug_lua      = ARGV[6] == "true"
local max_history  = tonumber(ARGV[7])
local script_name  = "delete.lua"
---------  END injected arguments ---------

--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------


--------  BEGIN delete.lua --------
log_debug("BEGIN delete", digest)

local redis_version = redis_version()
local count          = 0

log_debug("ZREM", digests, digest)
count = count + redis.call("ZREM", digests, digest)

if tonumber(redis_version["major"]) >= 4 then
  log_debug("UNLINK", digest, queued, primed, locked)
  count = count + redis.call("UNLINK", digest, queued, primed, locked)
else
  log_debug("DEL", digest, queued, primed, locked)
  count = count + redis.call("DEL", digest, queued, primed, locked)
end


log("Deleted (" .. count .. ") keys")
log_debug("END delete (" .. count .. ") keys for:", digest)

return count
--------  END delete.lua --------
