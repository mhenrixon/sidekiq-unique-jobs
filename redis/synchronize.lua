local unique_key     = KEYS[1]
local time           = ARGV[1]

if redis.pcall('set', unique_key, time + 60, 'nx', 'ex', 60) then
  return 1
end

local stored_time = redis.pcall('get', unique_key)
if stored_time and stored_time < time then
  if redis.pcall('set', unique_key, time + 60, 'xx', 'ex', 60) then
    return 1
  end
end

return 0
