local grabbed_key   = KEYS[1]
local unique_digest = KEYS[2]

local job_id = ARGV[1]

local function current_time()
  local time = redis.call('time')
  local s = time[1]
  local ms = time[2]
  local number = tonumber((s .. '.' .. ms))

  return number
end

local old_token  = redis.call('GET', unique_digest)
if old_token then
  if old_token == job_id or old_token == '2' then
    redis.call('DEL', unique_digest)
    redis.call('HSET', grabbed_key, job_id, current_time())
  end
end
