-------- BEGIN keys ---------
local digest  = KEYS[1]
local digests = KEYS[2]
--------  END keys  ---------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[1])
local debug_lua    = ARGV[2] == "true"
local max_history  = tonumber(ARGV[3])
local script_name  = tostring(ARGV[4]) .. ".lua"
---------  END injected arguments ---------

--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------

--------  BEGIN Variables  --------
local queued     = digest .. ":QUEUED"
local primed     = digest .. ":PRIMED"
local locked     = digest .. ":LOCKED"
local run_digest = digest .. ":RUN"
local run_queued = digest .. ":RUN:QUEUED"
local run_primed = digest .. ":RUN:PRIMED"
local run_locked = digest .. ":RUN:LOCKED"
--------   END Variables   --------


--------  BEGIN delete_by_digest.lua --------
local counter       = 0
local redis_version = redis_version()
local del_cmd   = "DEL"

log_debug("BEGIN delete_by_digest:", digest)

if redis_version["major"] >= 4 then del_cmd = "UNLINK"; end

log_debug(del_cmd, digest, queued, primed, locked, run_digest, run_queued, run_primed, run_locked)
counter = redis.call(del_cmd, digest, queued, primed, locked, run_digest, run_queued, run_primed, run_locked)

log_debug("ZREM", digests, digest)
redis.call("ZREM", digests, digest)

log_debug("END delete_by_digest:", digest, "(deleted " ..  counter .. " keys)")
return counter
--------   END delete_by_digest.lua  --------
