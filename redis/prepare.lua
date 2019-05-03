local digest    = KEYS[1]
local prepared  = KEYS[2]
local obtained  = KEYS[3]
local locked    = KEYS[4]
local changelog = KEYS[5]

local job_id       = ARGV[1]
local ttl          = tonumber(ARGV[2])
local lock_type    = ARGV[3]
local current_time = tonumber(ARGV[4])
local concurrency  = tonumber(ARGV[5])

local queued_count = redis.call('LLEN', prepared)
local locked_count = redis.call('HLEN', locked)
local within_limit = concurrency > locked_count
local limit_exceeded = not within_limit

local function log_debug( ... )
  local result = ""
  for i,v in ipairs(arg) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, "prepare.lua -" ..  result)
end

local function log(message, digest, job_id, time, prev_jid)

  local entry = cjson.encode({digest = digest, job_id = job_id, script = "prepare.lua", message = message, time = time, prev_jid = prev_jid })

  redis.call('ZADD', changelog, current_time, entry);
  redis.call('ZREMRANGEBYSCORE', changelog, '-inf', math.floor(current_time) - 86400000);
  redis.call('PUBLISH', changelog, entry);
end

-- BEGIN lock
log_debug("BEGIN prepare key: ", digest, " with job_id: ", job_id)

if redis.call('HEXISTS', locked, job_id) == 1 then
  log_debug("HEXISTS", locked, job_id, "== 1")
  log("Alredy locked", digest, job_id, current_time)
  return job_id
end

local prev_jid = redis.call('GET', digest)

if not prev_jid then
  log_debug("SET", digest, job_id)
  redis.call('SET', digest, job_id)
elseif prev_jid == job_id then
  log_debug(digest, "already prepared with job_id:", job_id)
  log("Attempted to prepare already prepared lock", digest, job_id, current_time)
else
  if within_limit and queued_count < concurrency then
    log_debug("Within limit:", digest, "(",  locked_count, "of", concurrency, ")")
    log_debug("SET", digest, job_id, "(was", prev_jid, ")")
    redis.call('SET', digest, job_id)
  else
    log_debug("Limit exceeded:", digest, "(",  locked_count, "of", concurrency, ")")
    log("Limit exceeded", digest, job_id, current_time, prev_jid)
    return prev_jid
  end
end

-- The Sidekiq client should only set ttl for until_expired
-- The Sidekiq server should set ttl for all other jobs
if lock_type == "until_expired" and ttl > 0 then
  log_debug("PEXPIRE", digest, ttl)
  redis.call('PEXPIRE', digest, ttl)
end

if within_limit and queued_count < concurrency then
  log_debug("LPUSH", prepared, job_id)
  redis.call('LPUSH', prepared, job_id)
else
  log_debug("Skipping LPUSH (" .. prepared .. " concurrency limited (" .. tostring(queued_count) .. " of " .. tostring(concurrency) .. " is used)")
end

log("Lock prepared successfully", digest, job_id, current_time)

log_debug("END prepare key: " .. digest .. " with job_id: " .. job_id)
return job_id
-- END lock
