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
