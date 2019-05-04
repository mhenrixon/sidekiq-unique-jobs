local digest    = KEYS[1]
local queued    = KEYS[2]
local primed    = KEYS[3]
local locked    = KEYS[4]
local changelog = KEYS[5]

local job_id       = ARGV[1]
local pttl         = tonumber(ARGV[2])
local lock_type    = ARGV[3]
local current_time = tonumber(ARGV[4])
local limit        = tonumber(ARGV[5])

local queued_count = redis.call('LLEN', queued)
local locked_count = redis.call('HLEN', locked)
local within_limit = limit > locked_count
local limit_exceeded = not within_limit
local verbose = true
local track   = true

local function log_debug( ... )
  if verbose == false then return end
  local result = ""
  for i,v in ipairs(arg) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, "queue.lua -" ..  result)
end

local function log(message, prev_jid)
  if track == false then return end
  local entry = cjson.encode({digest = digest, job_id = job_id, script = "queue.lua", message = message, time = current_time, prev_jid = prev_jid })

  redis.call('ZADD', changelog, current_time, entry);
  redis.call('ZREMRANGEBYSCORE', changelog, '-inf', math.floor(current_time) - 86400000);
  redis.call('PUBLISH', changelog, entry);
end

-- BEGIN lock
log_debug("BEGIN queue with key:", digest, "for job:", job_id)

if redis.call('HEXISTS', locked, job_id) == 1 then
  log_debug("HEXISTS", locked, job_id, "== 1")
  log("Duplicate")
  return job_id
end

local prev_jid = redis.call('GET', digest)
if not prev_jid then
  log_debug("SET", digest, job_id)
  redis.call('SET', digest, job_id)
elseif prev_jid == job_id then
  log_debug(digest, "already queued with job_id:", job_id)
  log("Duplicate")
  return job_id
else
  -- TODO: Consider constraining the total count of both locked and queued?
  if within_limit and queued_count < limit then
    log_debug("Within limit:", digest, "(",  locked_count, "of", limit, ")", "queued (", queued_count, "of", limit, ")")
    log_debug("SET", digest, job_id, "(was", prev_jid, ")")
    redis.call('SET', digest, job_id)
  else
    log_debug("Limit exceeded:", digest, "(",  locked_count, "of", limit, ")")
    log("Limit exceeded", prev_jid)
    return prev_jid
  end
end

if within_limit and queued_count < limit then
  log_debug("LPUSH", queued, job_id)
  redis.call('LPUSH', queued, job_id)
else
  log_debug("Skipping LPUSH (" .. queued .. " limit limited (" .. tostring(queued_count) .. " of " .. tostring(limit) .. " is used)")
  log("Limit Exceeded")
  return nil
end

-- The Sidekiq client should only set pttl for until_expired
-- The Sidekiq server should set pttl for all other jobs
if lock_type == "until_expired" and pttl > 0 then
  log_debug("PEXPIRE", digest, pttl)
  redis.call('PEXPIRE', digest, pttl)
  redis.call('PEXPIRE', queued, pttl)
end

log("Queued")
log_debug("END queue with key:", digest, "for job:", job_id)
return job_id
-- END lock
