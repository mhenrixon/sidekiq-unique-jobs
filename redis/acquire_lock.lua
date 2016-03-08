local unique_key = KEYS[1]
local job_id     = ARGV[1]
local expires    = ARGV[2]
local stored_jid = redis.pcall('get', unique_key)

if stored_jid then
  if stored_jid == job_id then
    return 1
  else
    -- maybe we should do something special in this case?
    return 0
  end
end

if redis.pcall('set', unique_key, job_id, 'nx', 'ex', expires) then
  redis.pcall('hsetnx', 'uniquejobs', job_id, unique_key)
  return 3
else
  return 2
end
