-- redis.replicate_commands();
local digest       = KEYS[1]
local current_time = ARGV[1]

local queued     = digest .. ':QUEUED'
local primed     = digest .. ':PRIMED'
local locked     = digest .. ':LOCKED'
local run_digest = digest .. ':RUN'
local run_queued = digest .. ':RUN:QUEUED'
local run_primed = digest .. ':RUN:PRIMED'
local run_locked = digest .. ':RUN:LOCKED'

local verbose = true
local track   = true

local function log_debug( ... )
  if verbose == false then return end
  local result = ""
  for i,v in ipairs(arg) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, "delete_by_digest.lua -" ..  result)
end

local function log(message)
  if track == false then return end
  local entry = cjson.encode({digest = digest, job_id = job_id, script = "delete_by_digest.lua", message = message, time = current_time })

  redis.call('ZADD', changelog, current_time, entry);
  redis.call('ZREMRANGEBYSCORE', changelog, '-inf', math.floor(current_time) - 86400000);
  redis.call('PUBLISH', changelog, entry);
end

local counter = 0

-- BEGIN lock
log_debug("BEGIN deletion of:", digest)

log_debug('DEL', digest, queued, primed, locked, run_digest, run_queued, run_primed, run_locked)
counter = redis.call('DEL', digest, queued, primed, locked, run_digest, run_queued, run_primed, run_locked)

log_debug("END deletion of:", digest, "(deleted", counter, "keys)")
return counter
