local lock_key  = KEYS[1]
local free_list = KEYS[2]
local held_list = KEYS[3]
local free_zet  = KEYS[4]
local held_zet  = KEYS[5]
local lock_hash = KEYS[6]

local job_id       = ARGV[1]
local ttl          = tonumber(ARGV[2])
local lock_type    = ARGV[3]
local current_time = tonumber(ARGV[4])
local concurrency  = tonumber(ARGV[5])

-- BEGIN unlock
redis.log(redis.LOG_DEBUG, "unlock.lua - BEGIN unlock for key: " .. lock_key .. " with job_id: " .. job_id)

if not redis.call('HEXIST', lock_hash, job_id) then
  redis.log(redis.LOG_DEBUG, "lock.lua - Not locked by: " .. lock_hash .. " with job_id: " .. job_id)
  return nil
end

redis.log(redis.LOG_DEBUG, "unlock.lua - ZREM " .. held_zet " " .. job_id)
redis.call('ZREM', held_zet, job_id)

redis.log(redis.LOG_DEBUG, "unlock.lua - LREM " .. held_list " -1 " .. job_id .. "(the last entry)")
redis.call('LREM', held_list, -1, job_id)

if ttl and ttl > 0 then
  redis.log(redis.LOG_DEBUG, "unlock.lua - Expiring keys in: " .. ttl)
  redis.call('PEXPIRE', unique_digest, ttl)

  redis.log(redis.LOG_DEBUG, "unlock.lua - PEXPIRE " .. held_zet " " .. tostring(ttl))
  redis.call('PEXPIRE', held_list, ttl)

  redis.log(redis.LOG_DEBUG, "unlock.lua - PEXPIRE " .. held_list " " .. tostring(ttl))
  redis.call('PEXPIRE', held_list, ttl)
else
  redis.call('DEL', unique_digest)

  redis.log(redis.LOG_DEBUG, "unlock.lua - PEXPIRE " .. held_zet " " .. tostring(ttl))
  redis.call('PEXPIRE', held_zet, 10)

  redis.log(redis.LOG_DEBUG, "unlock.lua - PEXPIRE " .. held_list " " .. tostring(ttl))
  redis.call('PEXPIRE', held_list, 10)
end

redis.log(redis.LOG_DEBUG, "unlock.lua - END unlock for key: " .. lock_key .. " with job_id: " .. job_id)
return job_id
