local exists_key    = KEYS[1]
local grabbed_key   = KEYS[2]
local available_key = KEYS[3]
local version_key   = KEYS[4]

redis.log(redis.LOG_DEBUG, "delete_locks.lua - forcefully deleting locks")
redis.call('DEL', exists_key)
redis.call('DEL', grabbed_key)
redis.call('DEL', available_key)
redis.call('DEL', version_key)
