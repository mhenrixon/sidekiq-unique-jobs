local queue        = KEYS[1]
local schedule_set = KEYS[2]
local retry_set    = KEYS[3]

local digest        = ARGV[1]

local function delete_from_sorted_set(name, digest)
  local per   = 50
  local total = redis.call('zcard', name)
  local index = 0
  local result
  -- redis.log(redis.LOG_DEBUG, "delete_from_sorted_set("..name..","..digest..")")
  while (index < total) do
    -- redis.log(redis.LOG_DEBUG, "delete_from_sorted_set("..name..","..digest..") - "..index.."-"..per)
    local items = redis.call('ZRANGE', name, index, index + per -1)
    for _, item in pairs(items) do
      -- redis.log(redis.LOG_DEBUG, "delete_from_sorted_set("..name..","..digest..") - current item: " .. item)
      if string.find(item, digest) then
        -- redis.log(redis.LOG_DEBUG, "delete_from_sorted_set("..name..","..digest..") - deleting item")
        redis.call('ZREM', name, item)
        result = item
        break
      end
    end
    index = index + per
  end
  return result
end

local per     = 50
local total   = redis.call('LLEN', queue)
local index   = 0
local result  = nil

-- redis.log(redis.LOG_DEBUG, "delete_job_by_digest.lua - looping through: " .. queue)
while (index < total) do
  -- redis.log(redis.LOG_DEBUG, "delete_job_by_digest.lua - " .. index .. "-" .. per)
  local items = redis.call('LRANGE', queue, index, index + per -1)
  for _, item in pairs(items) do
    -- redis.log(redis.LOG_DEBUG, "delete_job_by_digest.lua - item: " .. item)
    if string.find(item, digest) then
      -- redis.log(redis.LOG_DEBUG, "delete_job_by_digest.lua - found item with digest: " .. digest .. " in: " ..queue)
      redis.call('LREM', queue, 1, item)
      result = item
      break
    end
  end
  index = index + per
end

if result then
  return result
end

result = delete_from_sorted_set(schedule_set, digest)
if result then
  return result
end

result = delete_from_sorted_set(retry_set, digest)
return result
