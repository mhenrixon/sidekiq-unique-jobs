local unique_key = KEYS[1]
local job_id     = ARGV[1]
local stored_jid = redis.pcall('get', unique_key)

if stored_jid then
  if stored_jid == job_id or stored_jid == '2' then
    if redis.pcall('del', unique_key) then
      if redis.pcall('hdel', 'uniquejobs', job_id) then
        -- All should be good
        return 1
      else
        -- hdel has failed
        return 2
      end
    else
      -- del has failed, lets try hdel anyway.
      if redis.pcall('hdel', 'uniquejobs', job_id) then
        -- All should be good anyway ?
        return 3
      else
        -- hdel has failed
        return 4
      end
    end
  else
    return 0
  end
else
  return -1
end

