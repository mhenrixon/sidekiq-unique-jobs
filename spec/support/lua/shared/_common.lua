local function toboolean(val)
  val = tostring(val)
  return val == "1" or val == "true"
end

local function log_debug( ... )
  local result = ""
  for _,v in ipairs(arg) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, " - " ..  result)
end

