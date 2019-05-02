local lock_key  = KEYS[1]
local prepared = KEYS[2]
local obtained = KEYS[3]
local free_zet  = KEYS[4]
local held_zet  = KEYS[5]
local locked = KEYS[6]

local job_id       = ARGV[1]
local ttl          = tonumber(ARGV[2])
local lock_type    = ARGV[3]
local current_time = tonumber(ARGV[4])
local concurrency  = tonumber(ARGV[5])

-- BEGIN unlock
redis.log(redis.LOG_DEBUG, "unlock.lua - BEGIN unlock for key: " .. lock_key .. " with job_id: " .. job_id)

if not redis.call('HEXIST', locked, job_id) then
  redis.log(redis.LOG_DEBUG, "lock.lua - Not locked by: " .. locked .. " with job_id: " .. job_id)
  return nil
end

redis.log(redis.LOG_DEBUG, "unlock.lua - ZREM " .. held_zet " " .. job_id)
redis.call('ZREM', held_zet, job_id)

redis.log(redis.LOG_DEBUG, "unlock.lua - LREM " .. obtained " -1 " .. job_id .. "(the last entry)")
redis.call('LREM', obtained, -1, job_id)

if ttl and ttl > 0 then
  redis.log(redis.LOG_DEBUG, "unlock.lua - Expiring keys in: " .. ttl)
  redis.call('PEXPIRE', unique_digest, ttl)

  redis.log(redis.LOG_DEBUG, "unlock.lua - PEXPIRE " .. held_zet " " .. tostring(ttl))
  redis.call('PEXPIRE', obtained, ttl)

  redis.log(redis.LOG_DEBUG, "unlock.lua - PEXPIRE " .. obtained " " .. tostring(ttl))
  redis.call('PEXPIRE', obtained, ttl)
else
  redis.call('DEL', unique_digest)

  redis.log(redis.LOG_DEBUG, "unlock.lua - PEXPIRE " .. held_zet " " .. tostring(ttl))
  redis.call('PEXPIRE', held_zet, 10)

  redis.log(redis.LOG_DEBUG, "unlock.lua - PEXPIRE " .. obtained " " .. tostring(ttl))
  redis.call('PEXPIRE', obtained, 10)
end

redis.log(redis.LOG_DEBUG, "unlock.lua - END unlock for key: " .. lock_key .. " with job_id: " .. job_id)
return job_id
