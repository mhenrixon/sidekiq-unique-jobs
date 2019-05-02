local lock_key  = KEYS[1]
local prepared  = KEYS[2]
local obtained  = KEYS[3]
local locked    = KEYS[4]
local changelog = KEYS[5]

print("delete.lua - BEGIN delete keys for: " .. lock_key)

print("delete.lua - DEL " .. lock_key)
redis.call('DEL', lock_key)
print("delete.lua - DEL " .. prepared)
redis.call('DEL', prepared)
print("delete.lua - DEL " .. obtained)
redis.call('DEL', obtained)
print("delete.lua - DEL " .. locked)
redis.call('DEL', locked)

print("delete.lua - END delete keys for: " .. lock_key)

return 1
