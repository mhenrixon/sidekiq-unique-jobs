local unique_digest = KEYS[1]
local wait_key      = KEYS[2]
local work_key      = KEYS[3]
local unique_set    = KEYS[4]

redis.call('DEL', unique_digest)
redis.call('DEL', wait_key)
redis.call('DEL', work_key)
redis.call('ZREM', unique_set, unique_digest)

return 1
