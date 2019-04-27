local unique_digest = KEYS[1]     -- TODO: Legacy support (Remove in v6.1)
local exists_key    = KEYS[2]
local grabbed_key   = KEYS[3]
local available_key = KEYS[4]
local version_key   = KEYS[5]
local unique_set   = KEYS[6]

redis.call('DEL', unique_digest)  -- TODO: Legacy support (Remove in v6.1)
redis.call('DEL', exists_key)
redis.call('SREM', unique_set, unique_digest)
redis.call('DEL', grabbed_key)
redis.call('DEL', available_key)
redis.call('DEL', version_key)
redis.call('DEL', 'uniquejobs')   -- TODO: Old job hash, just drop the darn thing
