local queue   = KEYS[1]
local working = KEYS[2]

local job = redis.call("LMOVE", queue, working, "RIGHT", "LEFT")
if not job then
  return nil
end

local ok, item = pcall(cjson.decode, job)
if not ok then
  return {job, -1}
end

local digest = item["lock_digest"]
if not digest then
  return {job, -1}
end

local locked = digest .. ":LOCKED"
local jid = item["jid"]
local lock_valid = 0

if jid then
  lock_valid = redis.call("HEXISTS", locked, jid)
end

return {job, lock_valid}
