-- redis.replicate_commands();

local unique_digest = KEYS[1]
local work_key      = KEYS[2]

local job_id       = ARGV[1]
local current_time = ARGV[2]

redis.log(redis.LOG_DEBUG, "locked.lua - Is unique_digest: " .. unique_digest .. " locked by job_id: " .. job_id .. "?")

if redis.call('GET', unique_digest) == job_id then
  redis.log(redis.LOG_DEBUG, "locked.lua - locked with unique_digest")
  return 1
end

return -1
