-- redis.replicate_commands();
local unique_set   = KEYS[1]
local unique_digest = KEYS[2]

local wait_key          = unique_digest .. ':WAIT'
local work_key          = unique_digest .. ':WORK'
local run_key           = unique_digest .. ':RUN'
local run_wait_key      = unique_digest .. ':WAIT'
local run_work_key      = unique_digest .. ':WORK'

redis.call('ZREM', unique_set, unique_digest)
redis.call('ZREM', unique_set, run_key)
redis.call('DEL', unique_digest)
redis.call('DEL', wait_key)
redis.call('DEL', work_key)
redis.call('DEL', run_key)
redis.call('DEL', run_wait_key)
redis.call('DEL', run_work_key)

return 1
