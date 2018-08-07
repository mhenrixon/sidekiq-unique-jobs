local exists_key    = KEYS[1]
local grabbed_key   = KEYS[2]
local available_key = KEYS[3]
local version_key   = KEYS[4]
local unique_keys   = KEYS[5]
local unique_digest = KEYS[6] -- TODO: Legacy support (Remove in v6.1)

local token      = ARGV[1]
local expiration = tonumber(ARGV[2])

redis.call('HDEL', grabbed_key, token)
redis.call('SREM', unique_keys, unique_digest)
local available_count = redis.call('LPUSH', available_key, token)

if expiration then
  redis.log(redis.LOG_DEBUG, "signal_locks.lua - expiring stale locks")
  redis.call('SREM', unique_keys, unique_digest)
  redis.call('EXPIRE', exists_key, expiration)
  redis.call('EXPIRE', available_key, expiration)
  redis.call('EXPIRE', version_key, expiration)
  redis.call('EXPIRE', unique_digest, expiration) -- TODO: Legacy support (Remove in v6.1)
else
  redis.call('DEL', exists_key)
  redis.call('SREM', unique_keys, unique_digest)
  redis.call('DEL', grabbed_key)
  redis.call('DEL', available_key)
  redis.call('DEL', version_key)
  redis.call('DEL', 'uniquejobs')   -- TODO: Old job hash, just drop the darn thing  (Remove in v6.1)
  redis.call('DEL', unique_digest)  -- TODO: Legacy support (Remove in v6.1)
end

return available_count

