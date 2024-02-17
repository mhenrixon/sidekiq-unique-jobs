local function delete_from_queue(queue, digest)
  local per = 50
  local total = redis.call("LLEN", queue)
  local result = nil

  for index = 0, total, per do
    local items = redis.call("LRANGE", queue, index, index + per - 1)
    if #items == 0 then
      break
    end
    for _, item in ipairs(items) do
      if string.find(item, digest) then
        redis.call("LREM", queue, 1, item)
        result = item
        break
      end
    end
    if result then break end
  end

  return result
end
