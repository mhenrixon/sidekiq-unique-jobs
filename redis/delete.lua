local unique_digest = KEYS[1]
local wait_key      = KEYS[2]
local work_key      = KEYS[]
local exists_key    = KEYS[4]
local grabbed_key   = KEYS[5]
local available_key = KEYS[6]
local version_key   = KEYS[7]
local unique_set    = KEYS[8]

redis.call('DEL', unique_digest)
redis.call('DEL', wait_key)
redis.call('DEL', work_key)
redis.call('DEL', exists_key)
redis.call('SREM', unique_set, unique_digest)
redis.call('DEL', grabbed_key)
redis.call('DEL', available_key)
redis.call('DEL', version_key)
redis.call('DEL', 'uniquejobs')   -- TODO: Old job hash, just drop the darn thing
