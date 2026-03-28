-------- BEGIN keys ---------
local working_pattern = KEYS[1]
local heartbeat_key   = KEYS[2]
-------- END keys ---------


-------- BEGIN recover arguments ---------
local current_identity = ARGV[1]
-------- END recover arguments -----------


--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[2])
local debug_lua    = tostring(ARGV[3]) == "1"
local max_history  = tonumber(ARGV[4])
local script_name  = tostring(ARGV[5]) .. ".lua"
local redisversion = ARGV[6]
---------  END injected arguments ---------


--------  BEGIN local functions --------
local function log_debug_recover( ... )
  if debug_lua ~= true then return end

  local args = {...}
  local result = ""
  for _,v in ipairs(args) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, script_name .. " -" ..  result)
end
----------  END local functions ----------


---------  BEGIN recover.lua ---------
log_debug_recover("BEGIN recover identity:", current_identity)

-- Scan for working lists from dead processes
-- Working list key format: uniquejobs:working:{identity}
local recovered = 0
local cursor = "0"

repeat
  local result = redis.call("SCAN", cursor, "MATCH", working_pattern, "COUNT", 100)
  cursor = result[1]
  local keys = result[2]

  for _, working_key in ipairs(keys) do
    -- Extract identity from key: uniquejobs:working:{identity}
    local identity = string.match(working_key, "uniquejobs:working:(.+)$")

    -- Skip our own working list
    if identity and identity ~= current_identity then
      -- Check if this process is still alive via its heartbeat
      local heartbeat = "uniquejobs:heartbeat:" .. identity
      local alive = redis.call("EXISTS", heartbeat)

      if alive == 0 then
        -- Process is dead — recover all its jobs
        log_debug_recover("Dead process:", identity, "recovering jobs from:", working_key)

        local job_count = redis.call("LLEN", working_key)
        for i = 1, job_count do
          local job = redis.call("RPOP", working_key)
          if not job then break end

          -- Parse to find the original queue
          local ok, item = pcall(cjson.decode, job)
          if ok and item["queue"] then
            local queue_key = "queue:" .. item["queue"]
            redis.call("LPUSH", queue_key, job)
            recovered = recovered + 1
            log_debug_recover("Recovered job", item["jid"] or "unknown", "to", queue_key)
          else
            -- Can't determine queue — push to default
            redis.call("LPUSH", "queue:default", job)
            recovered = recovered + 1
            log_debug_recover("Recovered job to queue:default (no queue in payload)")
          end
        end

        -- Clean up the dead process's working list
        redis.call("UNLINK", working_key)
      end
    end
  end
until cursor == "0"

log_debug_recover("END recover:", recovered, "jobs recovered")
return recovered
----------  END recover.lua ----------
