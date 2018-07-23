local exists_key    = KEYS[1]
local grabbed_key   = KEYS[2]
local available_key = KEYS[3]
local version_key   = KEYS[4]
local unique_keys   = KEYS[5]
local unique_digest = KEYS[6]     -- TODO: Legacy support (Remove in v6.1)

redis.call('DEL', exists_key)
redis.call('SREM', unique_keys, unique_digest)
redis.call('DEL', grabbed_key)
redis.call('DEL', available_key)
redis.call('DEL', version_key)
redis.call('DEL', 'uniquejobs')   -- TODO: Old job hash, just drop the darn thing
redis.call('DEL', unique_digest)  -- TODO: Legacy support (Remove in v6.1)
