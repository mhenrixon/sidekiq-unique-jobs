local key_one = KEYS[1]
local key_two = KEYS[2]

local locked_val = ARGV[1]

redis.log(redis.LOG_DEBUG,  key_one .. " - " ..  key_two .. " - " .. locked_val)

if key_one == key_two then
  return -1
end

if redis.call("SET", key_two, locked_val, "NX") then
  return 1
end
