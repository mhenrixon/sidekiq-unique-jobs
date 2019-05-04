-- redis.replicate_commands();

local digest = KEYS[1]
local queued = KEYS[2]
local primed = KEYS[3]
local locked = KEYS[4]

local job_id       = ARGV[1]
local current_time = ARGV[2]
local concurrency  = ARGV[2]

local verbose = true

local hgetall = function (key)
  local bulk = redis.call('HGETALL', key)
  local result = {}
  local nextkey
  for i, v in ipairs(bulk) do
    if i % 2 == 1 then
      nextkey = v
    else
      result[nextkey] = v
    end
  end
  return result
end

local function log_debug( ... )
  if verbose == false then return end
  local result = ""
  for i,v in ipairs(arg) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, "locked.lua -" ..  result)
end

if redis.call('HEXISTS', locked, job_id) == 1 then
  log_debug("Locked - digest:", digest, "job_id:", job_id)
  return 1
else
  local result      = ""

  for k,v in pairs(hgetall(locked)) do
    result = result .. " job_id: " .. k .. " locked_at: " .. v
  end
  log_debug("Not locked - digest:", digest, "job_id:", job_id, "locked_jids:", result)
  return -1
end
