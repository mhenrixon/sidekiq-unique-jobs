local function delete_from_sorted_set(name, digest)
  local cursor = "0"
  local result = nil
  local match_pattern = "*" .. digest .. "*"

  repeat
    local scan_result = redis.call("ZSCAN", name, cursor, "MATCH", match_pattern, "COUNT", 1)
    cursor = scan_result[1]
    local items = scan_result[2]

    for i = 1, #items, 2 do
      local item = items[i]
      if string.find(item, digest) then
        redis.call("ZREM", name, item)
        result = item
        break
      end
    end
  until cursor == "0" or result ~= nil

  return result
end
