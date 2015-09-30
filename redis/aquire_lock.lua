local unique_key     = KEYS[1]
local job_id         = ARGV[1]
local expires        = ARGV[2]

if redis.pcall('set', unique_key, job_id, 'nx', 'ex', expires) then
  return 1
else
  return 0
end
