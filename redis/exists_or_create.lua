-- redis.replicate_commands();

local exists_key      = KEYS[1]
local grabbed_key     = KEYS[2]
local available_key   = KEYS[3]
local current_jid     = ARGV[1]
local expiration      = tonumber(ARGV[2])
local persisted_jid = redis.call('GETSET', exists_key, current_jid)

if persisted_jid then
  redis.log(redis.LOG_DEBUG, "exists_or_create.lua - returning persisted_jid : " .. persisted_jid)
  return persisted_jid
else
  redis.call('EXPIRE', exists_key, 10)
  redis.call('DEL', grabbed_key)
  redis.call('DEL', available_key)
  redis.log(redis.LOG_DEBUG, "exists_or_create.lua - pushing available_key : " .. available_key .. " with jid : " .. current_jid)
  redis.call('RPUSH', available_key, current_jid)

  redis.call('PERSIST', exists_key)

  if expiration then
    redis.log(redis.LOG_DEBUG, "exists_or_create.lua - expiring locks in : " .. expiration)
    redis.call('EXPIRE', available_key, expiration)
    redis.call('EXPIRE', exists_key, expiration)
  end

  return current_jid
end
