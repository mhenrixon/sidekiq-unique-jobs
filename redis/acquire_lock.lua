local unique_key = KEYS[1]
local job_id     = ARGV[1]
local expires    = tonumber(ARGV[2])
local stored_jid = redis.pcall('get', unique_key)

if stored_jid then
  if stored_jid == job_id then
    return 1
  else
    return 0
  end
end

if redis.call('SET', unique_key, job_id, 'nx') then
  if expires then
    redis.call('EXPIRE', unique_key, expires)
  end
  return 1
else
  return 0
end
