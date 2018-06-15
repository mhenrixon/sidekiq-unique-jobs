local exists_key    = KEYS[1]
local grabbed_key   = KEYS[2]
local available_key = KEYS[3]
local version_key   = KEYS[4]

local token      = ARGV[1]
local expiration = tonumber(ARGV[2])

redis.call('HDEL', grabbed_key, token)
redis.call('LPUSH', available_key, token)

if expiration then
  redis.log(redis.LOG_DEBUG, "signal_locks.lua - expiring stale locks")
  redis.call('EXPIRE', exists_key, expiration)
  redis.call('EXPIRE', available_key, expiration)
  redis.call('EXPIRE', version_key, expiration)
end
