local working = KEYS[1]
local locked  = KEYS[2]
local digests = KEYS[3]

local job       = ARGV[1]
local jid       = ARGV[2]
local digest    = ARGV[3]
local lock_type = ARGV[4]

redis.call("LREM", working, 1, job)

if not digest or digest == "" then
  return 1
end

if lock_type == "until_expired" then
  return 1
end

if lock_type == "while_executing" or lock_type == "until_and_while_executing" then
  return 1
end

local holds_lock = redis.call("HEXISTS", locked, jid)
if holds_lock == 1 then
  redis.call("HDEL", locked, jid)

  if redis.call("HLEN", locked) == 0 then
    redis.call("ZREM", digests, digest)
    redis.call("UNLINK", locked)
  end
end

return 1
