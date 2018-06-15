-- redis.replicate_commands();

local exists_key    = KEYS[1]
local grabbed_key   = KEYS[2]
local available_key = KEYS[3]
local version_key   = KEYS[4]

local current_jid   = ARGV[1]
local expiration    = tonumber(ARGV[2])
local api_version   = ARGV[3]
local resources     = tonumber(ARGV[4])
local stored_jid    = redis.call('GETSET', exists_key, current_jid)

if stored_jid then
  redis.log(redis.LOG_DEBUG, "create_locks.lua - returning stored_jid : " .. stored_jid)
  return stored_jid
else
  redis.call('EXPIRE', exists_key, 10)
  redis.call('DEL', grabbed_key)
  redis.call('DEL', available_key)

  redis.log(redis.LOG_DEBUG, "create_locks.lua - pushing available_key : " .. available_key .. " with jid : " .. current_jid)

  for index = 1, resources do
    redis.call('RPUSH', available_key, index)
  end
  redis.call('GETSET', version_key, api_version)
  redis.call('PERSIST', exists_key)

  if expiration then
    redis.log(redis.LOG_DEBUG, "create_locks.lua - expiring locks in : " .. expiration)
    redis.call('EXPIRE', available_key, expiration)
    redis.call('EXPIRE', exists_key, expiration)
    redis.call('EXPIRE', version_key, expiration)
  end

  return current_jid
end
