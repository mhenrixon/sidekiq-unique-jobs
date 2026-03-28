local locked  = KEYS[1]
local digests = KEYS[2]

local job_id    = ARGV[1]
local lock_type = ARGV[2]

if lock_type == "until_expired" then
  return job_id
end

local holds_lock = redis.call("HEXISTS", locked, job_id) == 1
if not holds_lock then
  if redis.call("HLEN", locked) == 0 then
    local digest = string.gsub(locked, ":LOCKED$", "")
    redis.call("ZREM", digests, digest)
    return job_id
  end
  return nil
end

redis.call("HDEL", locked, job_id)

if redis.call("HLEN", locked) == 0 then
  local digest = string.gsub(locked, ":LOCKED$", "")
  redis.call("ZREM", digests, digest)
  redis.call("UNLINK", locked)
end

return job_id
