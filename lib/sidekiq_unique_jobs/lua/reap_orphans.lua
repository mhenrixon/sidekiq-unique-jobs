redis.replicate_commands()

-------- BEGIN keys ---------
local digests_set  = KEYS[1]
local schedule_set = KEYS[2]
local retry_set    = KEYS[3]
--------  END keys  ---------

-------- BEGIN argv ---------
local reaper_count  = tonumber(ARGV[1])
--------  END argv  ---------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[2])
local debug_lua    = ARGV[3] == "true"
local max_history  = tonumber(ARGV[4])
local script_name  = ARGV[5] .. ".lua"
---------  END injected arguments ---------


--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
<%= include_partial "shared/_find_digest_in_queues.lua" %>
<%= include_partial "shared/_find_digest_in_sorted_set.lua" %>
----------  END local functions ----------


--------  BEGIN delete_orphaned.lua --------
log_debug("BEGIN")
local found     = false
local per       = 50
local total     = redis.call("ZCARD", digests_set)
local index     = 0
local del_count = 0
local redis_ver = redis_version()
local del_cmd   = "DEL"

if tonumber(redis_ver["major"]) >= 4 then del_cmd = "UNLINK"; end

repeat
  log_debug("Interating through:", digests_set, "for orphaned locks")
  local digests  = redis.call("ZREVRANGE", digests_set, index, index + per -1)

  for _, digest in pairs(digests) do
    log_debug("Searching for digest:", digest, "in", schedule_set)
    found = find_digest_in_sorted_set(schedule_set, digest)

    if found ~= true then
      log_debug("Searching for digest:", digest, "in", retry_set)
      found = find_digest_in_sorted_set(retry_set, digest)
    end

    if found ~= true then
      log_debug("Searching for digest:", digest, "in all queues")
      local queue = find_digest_in_queues(digest)

      if queue then
        log_debug("found digest:", digest, "in queue:", queue)
        found = true
      end
    end

    if found ~= true then
      local queued     = digest .. ":QUEUED"
      local primed     = digest .. ":PRIMED"
      local locked     = digest .. ":LOCKED"
      local info       = digest .. ":INFO"
      local run_digest = digest .. ":RUN"
      local run_queued = digest .. ":RUN:QUEUED"
      local run_primed = digest .. ":RUN:PRIMED"
      local run_locked = digest .. ":RUN:LOCKED"
      local run_info   = digest .. ":RUN:INFO"


      log_debug(del_cmd, digest, queued, primed, locked, info, run_digest, run_queued, run_primed, run_locked, run_info)
      redis.call(del_cmd, digest, queued, primed, locked, info, run_digest, run_queued, run_primed, run_locked, run_info)
      log_debug("ZREM", digests_set, digest)
      redis.call("ZREM", digests_set, digest)
      del_count = del_count + 1
    end
  end

  index = index + per
until index >= total or del_count >= reaper_count

log_debug("END")
return del_count
