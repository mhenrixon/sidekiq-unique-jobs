-------- BEGIN keys ---------
local digests      = KEYS[1]
local schedule_set = KEYS[2]
local retry_set    = KEYS[3]
--------  END keys  ---------

-------- BEGIN argv ---------
local count = tonumber(ARGV[1])
--------  END argv  ---------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[2])
local verbose      = ARGV[3] == "true"
local max_history  = tonumber(ARGV[4])
local script_name  = "delete_orphaned.lua"
---------  END injected arguments ---------


--------  BEGIN local functions --------
<%= include_partial 'shared/_common.lua' %>
<%= include_partial 'shared/_find_digest_in_queues.lua' %>
<%= include_partial 'shared/_find_digest_in_sorted_set.lua' %>
----------  END local functions ----------


--------  BEGIN delete_orphaned.lua --------
local cursor = 0
local per    = 100
local index  = 0
local result = nil

while (index < count) do
  local digs = redis.call('ZREVRANGE', digests, index, index + per -1)
  for _, digest in pairs(digs) do
    local pattern = "*" .. digest .. "*"
    local found = find_digest_in_queues("queue:*", pattern)
    found = tonumber(found)
    if found and found > 0 then
      break
    end
  end
  index = index + per
end
return result
--------   END delete_orphaned.lua  --------
