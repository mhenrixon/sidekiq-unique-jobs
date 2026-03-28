local digests = KEYS[1]

local reaper_count = tonumber(ARGV[1])

local del_count = 0
local cursor = "0"

repeat
  local result = redis.call("ZSCAN", digests, cursor, "COUNT", 50)
  cursor = result[1]
  local entries = result[2]

  for i = 1, #entries, 2 do
    local digest = entries[i]
    local locked = digest .. ":LOCKED"

    if redis.call("EXISTS", locked) == 0 then
      redis.call("ZREM", digests, digest)
      del_count = del_count + 1

      if del_count >= reaper_count then
        return del_count
      end
    end
  end
until cursor == "0"

return del_count
