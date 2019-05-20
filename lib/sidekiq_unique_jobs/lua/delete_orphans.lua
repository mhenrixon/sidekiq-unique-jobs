-------- BEGIN keys ---------
local digests_set  = KEYS[1]
local schedule_set = KEYS[2]
local retry_set    = KEYS[3]
--------  END keys  ---------

-------- BEGIN argv ---------
local max_orphans  = tonumber(ARGV[1])
--------  END argv  ---------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[2])
local verbose      = ARGV[3] == "true"
local max_history  = tonumber(ARGV[4])
local script_name  = "delete_orphaned.lua"
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

while(index < max_orphans) do
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
      found = find_digest_in_queues(digest)
    end

    if found ~= true then
      local queued     = digest .. ":QUEUED"
      local primed     = digest .. ":PRIMED"
      local locked     = digest .. ":LOCKED"
      local run_digest = digest .. ":RUN"
      local run_queued = digest .. ":RUN:QUEUED"
      local run_primed = digest .. ":RUN:PRIMED"
      local run_locked = digest .. ":RUN:LOCKED"

      redis.call("DEL", digest, queued, primed, locked, run_digest, run_queued, run_primed, run_locked)
      redis.call("ZREM", digests_set, digest)
      del_count = del_count + 1
    end
  end

  index = index + per
end
