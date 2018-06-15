redis.replicate_commands();

local exists_key           = KEYS[1]
local grabbed_key          = KEYS[2]
local available_key        = KEYS[3]
local release_key          = KEYS[4]
local version_key          = KEYS[5]

local expires_in           = tonumber(ARGV[1])
local stale_client_timeout = tonumber(ARGV[2])
local expiration           = tonumber(ARGV[3])

local function current_time()
  local time = redis.call('time')
  local s = time[1]
  local ms = time[2]
  local number = tonumber((s .. '.' .. ms))

  return number
end

local hgetall = function (key)
  local bulk = redis.call('HGETALL', key)
  local result = {}
  local nextkey
  for i, v in ipairs(bulk) do
    if i % 2 == 1 then
      nextkey = v
    else
      result[nextkey] = v
    end
  end
  return result
end

local cached_current_time = current_time()
redis.log(redis.LOG_DEBUG, "release_stale_locks.lua - started at : " .. cached_current_time)

local my_lock_expires_at = cached_current_time + expires_in + 1
redis.log(redis.LOG_DEBUG, "release_stale_locks.lua - my_lock_expires_at: " .. my_lock_expires_at)

if not redis.call('SETNX', release_key, my_lock_expires_at) then
  -- Check if expired
  local other_lock_expires_at = tonumber(redis.call('GET', release_key))
  redis.log(redis.LOG_DEBUG, "release_stale_locks.lua - other_lock_expires_at: " .. other_lock_expires_at)

  if other_lock_expires_at < cached_current_time then
    local old_expires_at = tonumber(redis.call('GETSET', release_key, my_lock_expires_at))
    redis.log(redis.LOG_DEBUG, "release_stale_locks.lua - old_expires_at: " .. old_expires_at)

    -- Check if another client started cleanup yet. If not,
    -- then we now have the lock.
    if not old_expires_at == other_lock_expires_at then
      redis.log(redis.LOG_DEBUG, "release_stale_locks.lua -could not retrieve lock: exiting 0")
      return 0
    end
  end
end

local keys = hgetall(grabbed_key)
for key, locked_at in pairs(keys) do
  local timed_out_at = tonumber(locked_at) + stale_client_timeout
  redis.log(redis.LOG_DEBUG,
    "release_stale_locks.lua - processing: " .. grabbed_key .. " key: " .. key .. " locked_at: " .. locked_at
  )

  if timed_out_at < current_time() then
    redis.log(redis.LOG_DEBUG, "HDEL " .. grabbed_key .. ":" .. key)
    redis.call('HDEL', grabbed_key, key)
    redis.log(redis.LOG_DEBUG, "LPUSH " .. available_key .. ":" .. key)
    redis.call('LPUSH', available_key, key)

    if expiration then
      redis.log(redis.LOG_DEBUG, "release_stale_locks.lua - EXPIRE " .. available_key .. " with " .. expiration)
      redis.call('EXPIRE', available_key, expiration)
      redis.log(redis.LOG_DEBUG, "release_stale_locks.lua - EXPIRE " .. exists_key .. " with " .. expiration)
      redis.call('EXPIRE', exists_key, expiration)
    end
  end
end

-- Make sure not to delete the lock in case someone else already expired
-- our lock, with one second in between to account for some lag.
if my_lock_expires_at > (current_time() - 1) then
  redis.log(redis.LOG_DEBUG, "release_stale_locks.lua - DEL " .. release_key)
  redis.call('DEL', release_key)
end

redis.log(redis.LOG_DEBUG, "release_stale_locks.lua - comleted at : " .. current_time())
return 1
