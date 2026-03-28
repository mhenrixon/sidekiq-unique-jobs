-------- BEGIN keys ---------
local queue   = KEYS[1]
local working = KEYS[2]
-------- END keys ---------


-------- BEGIN fetch arguments ---------
-- No custom arguments needed
-------- END fetch arguments -----------


--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[1])
local debug_lua    = tostring(ARGV[2]) == "1"
local max_history  = tonumber(ARGV[3])
local script_name  = tostring(ARGV[4]) .. ".lua"
local redisversion = ARGV[5]
---------  END injected arguments ---------


--------  BEGIN local functions --------
local function log_debug_fetch( ... )
  if debug_lua ~= true then return end

  local args = {...}
  local result = ""
  for _,v in ipairs(args) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, script_name .. " -" ..  result)
end
----------  END local functions ----------


---------  BEGIN fetch.lua ---------
log_debug_fetch("BEGIN fetch queue:", queue, "working:", working)

-- Atomically move job from queue to working list
-- LMOVE: source, destination, wherefrom, whereto
-- RIGHT = pop from tail (oldest job first, FIFO)
-- LEFT  = push to head of working list
local job = redis.call("LMOVE", queue, working, "RIGHT", "LEFT")
if not job then
  return nil
end

log_debug_fetch("Fetched job from", queue)

-- Parse job to validate lock state
local ok, item = pcall(cjson.decode, job)
if not ok then
  -- Not valid JSON — pass through (shouldn't happen but be safe)
  return {job, -1}
end

local digest = item["lock_digest"]
if not digest then
  -- Not a unique job — pass through without lock validation
  return {job, -1}
end

-- Validate: does this job's lock still exist?
local locked = digest .. ":LOCKED"
local jid = item["jid"]
local lock_valid = 0

if jid then
  lock_valid = redis.call("HEXISTS", locked, jid)
end

log_debug_fetch("END fetch job_id:", jid or "nil", "lock_valid:", lock_valid)
return {job, lock_valid}
----------  END fetch.lua ----------
