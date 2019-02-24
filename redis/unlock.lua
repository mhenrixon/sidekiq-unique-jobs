local exists_key    = KEYS[1]
local grabbed_key   = KEYS[2]
local available_key = KEYS[3]
local version_key   = KEYS[4]
local unique_keys   = KEYS[5]
local unique_digest = KEYS[6] -- TODO: Legacy support (Remove in v6.1)

local token = ARGV[1]
local ttl   = tonumber(ARGV[2])
local lock  = ARGV[3]

redis.call('SREM', unique_keys, unique_digest)

if ttl then
  redis.call('SREM', unique_keys, unique_digest)
  redis.call('EXPIRE', exists_key, ttl)
  redis.call('EXPIRE', grabbed_key, ttl)
  redis.call('EXPIRE', available_key, ttl)
  redis.call('EXPIRE', version_key, ttl)   -- TODO: Legacy support (Remove in v6.1)
  redis.call('EXPIRE', unique_digest, ttl) -- TODO: Legacy support (Remove in v6.1)
else
  redis.call('DEL', exists_key)
  redis.call('SREM', unique_keys, unique_digest)
  redis.call('DEL', grabbed_key)
  redis.call('DEL', available_key)
  redis.call('DEL', version_key)    -- TODO: Legacy support (Remove in v6.1)
  redis.call('DEL', 'uniquejobs')   -- TODO: Old job hash, just drop the darn thing  (Remove in v6.1)
  redis.call('DEL', unique_digest)  -- TODO: Legacy support (Remove in v6.1)
end

redis.call('HDEL', grabbed_key, token)
local count = redis.call('LPUSH', available_key, token)
redis.call('EXPIRE', available_key, 5)
return count

