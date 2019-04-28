-- redis.replicate_commands();
local unique_set   = KEYS[1]
local unique_digest = KEYS[2]

local exists_key        = unique_digest .. ':EXISTS'
local wait_key          = unique_digest .. ':WAIT'
local work_key          = unique_digest .. ':WORK'
local exists_key        = unique_digest .. ':EXISTS'
local grabbed_key       = unique_digest .. ':GRABBED'
local available_key     = unique_digest .. ':AVAILABLE'
local version_key       = unique_digest .. ':VERSION'
local run_key           = unique_digest .. ':RUN'
local run_wait_key      = unique_digest .. ':WAIT'
local run_work_key      = unique_digest .. ':WORK'
local run_exists_key    = unique_digest .. ':RUN:EXISTS'
local run_grabbed_key   = unique_digest .. ':RUN:GRABBED'
local run_available_key = unique_digest .. ':RUN:AVAILABLE'
local run_version_key   = unique_digest .. ':RUN:VERSION'

redis.call('SREM', unique_set, unique_digest)
redis.call('DEL', unique_digest)
redis.call('DEL', wait_key)
redis.call('DEL', work_key)
redis.call('DEL', grabbed_key)
redis.call('DEL', available_key)
redis.call('DEL', version_key)
redis.call('DEL', run_key)
redis.call('DEL', run_working_key)
redis.call('DEL', run_working_key)
redis.call('DEL', run_exists_key)
redis.call('DEL', run_grabbed_key)
redis.call('DEL', run_available_key)
redis.call('DEL', run_version_key)

return 1
