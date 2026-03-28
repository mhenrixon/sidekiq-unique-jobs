local working_pattern  = KEYS[1]
local current_identity = ARGV[1]

local recovered = 0
local cursor = "0"

repeat
  local result = redis.call("SCAN", cursor, "MATCH", working_pattern, "COUNT", 100)
  cursor = result[1]
  local keys = result[2]

  for _, working_key in ipairs(keys) do
    local identity = string.match(working_key, "uniquejobs:working:(.+)$")

    if identity and identity ~= current_identity then
      local heartbeat = "uniquejobs:heartbeat:" .. identity
      local alive = redis.call("EXISTS", heartbeat)

      if alive == 0 then
        local job_count = redis.call("LLEN", working_key)
        for i = 1, job_count do
          local job = redis.call("RPOP", working_key)
          if not job then break end

          local ok, item = pcall(cjson.decode, job)
          if ok and item["queue"] then
            redis.call("LPUSH", "queue:" .. item["queue"], job)
          else
            redis.call("LPUSH", "queue:default", job)
          end
          recovered = recovered + 1
        end

        redis.call("UNLINK", working_key)
      end
    end
  end
until cursor == "0"

return recovered
