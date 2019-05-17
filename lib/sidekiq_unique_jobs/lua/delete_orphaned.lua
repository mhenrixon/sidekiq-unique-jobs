-------- BEGIN keys ---------
local digests      = KEYS[1]
local schedule_set = KEYS[3]
local retry_set    = KEYS[4]
--------  END keys  ---------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[2])
local verbose      = ARGV[3] == "true"
local max_history  = tonumber(ARGV[4])
local script_name  = "delete_orphaned.lua.lua"
---------  END injected arguments ---------


--------  BEGIN local functions --------
<%= include_partial 'shared/_common.lua' %>
<%= include_partial 'shared/_find_digest_in_queues.lua' %>
<%= include_partial 'shared/_find_digest_in_sorted_set.lua' %>
----------  END local functions ----------

local cursor = 0
local per    = 50
local total  = redis.call('ZCARD', digests)
local index  = 0
local result = nil

while (index < total) do
  local digs = redis.call('ZREVRANGE', digests, index, index + per -1)
  for _, digest in pairs(digs) do
    local pattern = "*" .. digest .. "*"
    if find_digest_in_queues("queue:*", pattern)
  end
  index = index + per
end
return result

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
