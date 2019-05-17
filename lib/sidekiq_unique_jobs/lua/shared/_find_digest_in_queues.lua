local function find_digest_in_queues(name, pattern)
  local cursor = 0
  local count  = 10
  local result = nil

  local scan_match = redis.call('SCAN', name, cursor, 'MATCH', pattern, 'COUNT', count)
  return #scan_match[2]
end
