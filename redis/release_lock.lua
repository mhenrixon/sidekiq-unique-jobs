local unique_key = KEYS[1]
local job_id     = ARGV[1]
local stored_jid = redis.pcall('get', unique_key)

if stored_jid then
  if stored_jid == job_id then
    return redis.pcall('del', unique_key)
  else
    return 0
  end
else
  return -1
end

