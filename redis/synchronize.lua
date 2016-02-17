local unique_key     = KEYS[1]
local time           = ARGV[1]
local expires        = ARGV[2]

if redis.pcall('set', unique_key, time + expires, 'nx', 'ex', expires) then
  return 1
end

local stored_time = redis.pcall('get', unique_key)
if stored_time and stored_time < time then
  if redis.pcall('set', unique_key, time + expires, 'xx', 'ex', expires) then
    return 1
  end
end

return 0
