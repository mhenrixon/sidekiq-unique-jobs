local function delete_from_sorted_set(name, digest)
  local score  = redis.call("ZSCORE", "uniquejobs:digests", digest)
  local total  = redis.call("ZCARD", name)
  local per    = 50

  for offset = 0, total, per do
    local items

    if score then
      items = redis.call("ZRANGE", name, score, "+inf", "BYSCORE", "LIMIT", offset, per)
    else
      items = redis.call("ZRANGE", name, offset, offset + per -1)
    end

    if #items == 0 then
      break
    end

    for _, item in pairs(items) do
      if string.find(item, digest) then
        redis.call("ZREM", name, item)

        return item
      end
    end
  end

  return nil
end
