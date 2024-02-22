local function delete_from_queue(queue, digest)
  local total = redis.call("LLEN", queue)
  local per   = 50

  for index = 0, total, per do
    local items = redis.call("LRANGE", queue, index, index + per - 1)

    if #items == 0 then
      break
    end

    for _, item in pairs(items) do
      if string.find(item, digest) then
        redis.call("LREM", queue, 1, item)

        return item
      end
    end
  end

  return nil
end
