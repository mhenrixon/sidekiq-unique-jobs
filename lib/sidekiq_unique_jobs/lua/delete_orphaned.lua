-------- BEGIN keys ---------
local digests      = KEYS[1]
local schedule_set = KEYS[3]
local retry_set    = KEYS[4]
--------  END keys  ---------

local cursor = 0

redis.call("ZSCAN", digests, cursor,

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[2])
local verbose      = ARGV[3] == "true"
local max_history  = tonumber(ARGV[4])
local script_name  = "delete_job_by_digest.lua"
---------  END injected arguments ---------


--------  BEGIN local functions --------
<%= include_partial 'shared/_common.lua' %>
<%= include_partial 'shared/_delete_from_queue.lua' %>
<%= include_partial 'shared/_delete_from_sorted_set.lua' %>
----------  END local functions ----------


--------  BEGIN delete_job_by_digest.lua --------
result = delete_from_queue(queue, digest)
if result then
  return result
end

result = delete_from_sorted_set(schedule_set, digest)
if result then
  return result
end

result = delete_from_sorted_set(retry_set, digest)
return result
--------   END delete_job_by_digest.lua  --------
