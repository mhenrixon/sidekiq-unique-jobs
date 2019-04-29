local unique_digest = KEYS[1]
local wait_key      = KEYS[2]
local work_key      = KEYS[3]
local version_key   = KEYS[4]
local unique_set    = KEYS[5]

redis.call('DEL', unique_digest)
redis.call('DEL', wait_key)
redis.call('DEL', work_key)
redis.call('ZREM', unique_set, unique_digest)
redis.call('DEL', version_key)

return 1
