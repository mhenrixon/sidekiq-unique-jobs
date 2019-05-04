local digest    = KEYS[1]
local queued    = KEYS[2]
local primed    = KEYS[3]
local locked    = KEYS[4]
local changelog = KEYS[5]

local job_id       = ARGV[1]
local current_time = ARGV[2]
local verbose = false
local track   = true

local function log_debug( ... )
  if verbose == false then return end
  local result = ""
  for i,v in ipairs(arg) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, "delete.lua -" ..  result)
end

local function log(message)
  if track == false then return end
  local entry = cjson.encode({digest = digest, job_id = job_id, script = "delete.lua", message = message, time = current_time })

  log_debug('ZADD', changelog, current_time, entry);
  redis.call('ZADD', changelog, current_time, entry);
  redis.call('ZREMRANGEBYSCORE', changelog, '-inf', math.floor(current_time) - 86400000);
  redis.call('PUBLISH', changelog, entry);
end

log_debug("BEGIN delete keys for:", digest)

log_debug("DEL", digest)
redis.call('DEL', digest)

log_debug("DEL", queued)
redis.call('DEL', queued)

log_debug("DEL", primed)
redis.call('DEL', primed)

log_debug("DEL", locked)
redis.call('DEL', locked)


log("Deleted")
log_debug("END delete keys for:", digest)

return 1
