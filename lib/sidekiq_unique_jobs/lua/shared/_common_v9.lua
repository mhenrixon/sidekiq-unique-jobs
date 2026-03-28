local function toversion(version)
  local _, _, maj, min, pat = string.find(version, "(%d+)%.(%d+)%.(%d+)")

  return {
    ["version"] = version,
    ["major"]   = tonumber(maj),
    ["minor"]   = tonumber(min),
    ["patch"]   = tonumber(pat)
  }
end

local function log_debug( ... )
  if debug_lua ~= true then return end

  local args = {...}
  local result = ""
  for _,v in ipairs(args) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, script_name .. " -" ..  result)
end
