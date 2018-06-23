-- redis.replicate_commands();

local exists_key    = KEYS[1]
local grabbed_key   = KEYS[2]
local available_key = KEYS[3]
local version_key   = KEYS[4]

local exists_token  = ARGV[1]
local expiration    = tonumber(ARGV[2])
local api_version   = ARGV[3]
local concurrency   = tonumber(ARGV[4])
local stored_token  = redis.call('GETSET', exists_key, exists_token)

if stored_token then
  redis.log(redis.LOG_DEBUG, "create_locks.lua - returning stored_token : " .. stored_token)
  return stored_token
else
  redis.call('EXPIRE', exists_key, 10)
  redis.call('DEL', grabbed_key)
  redis.call('DEL', available_key)

  if concurrency and concurrency > 1 then
    for index = 1, concurrency do
      redis.call('RPUSH', available_key, index)
    end
  else
    redis.call('RPUSH', available_key, exists_token)
  end
  redis.call('GETSET', version_key, api_version)
  redis.call('PERSIST', exists_key)

  if expiration then
    redis.log(redis.LOG_DEBUG, "create_locks.lua - expiring locks in : " .. expiration)
    redis.call('EXPIRE', available_key, expiration)
    redis.call('EXPIRE', exists_key, expiration)
    redis.call('EXPIRE', version_key, expiration)
  end

  return 1
end
