-- redis.replicate_commands();
local unique_keys       = KEYS[1]
local unique_digest     = KEYS[2]
local exists_key        = KEYS[3]
local grabbed_key       = KEYS[4]
local available_key     = KEYS[5]
local version_key       = KEYS[6]
local run_exists_key    = KEYS[7]
local run_grabbed_key   = KEYS[8]
local run_available_key = KEYS[9]
local run_version_key   = KEYS[10]

local count = redis.call('SREM', unique_keys, unique_digest)
redis.call('DEL', exists_key)
redis.call('DEL', grabbed_key)
redis.call('DEL', available_key)
redis.call('DEL', version_key)
redis.call('DEL', run_exists_key)
redis.call('DEL', run_grabbed_key)
redis.call('DEL', run_available_key)
redis.call('DEL', run_version_key)

return count
