local function find_digest_in_process_set(digest)
  local process_cursor = 0
  local job_cursor     = 0
  local pattern        = "*" .. digest .. "*"
  local found          = false

  log_debug("searching in list processes:",
            "for digest:", digest,
            "cursor:", process_cursor)

  repeat
    local process_paginator   = redis.call("SSCAN", "processes", process_cursor, "MATCH", "*")
    local next_process_cursor = process_paginator[1]
    local processes           = process_paginator[2]
    log_debug("Found number of processes:", #processes, "next cursor:", next_process_cursor)

    for _, process in ipairs(processes) do
      log_debug("searching in process set:", process,
                "for digest:", digest,
                "cursor:", process_cursor)

      local job = redis.call("HGET", process, "info")

      if string.find(job, digest) then
        log_debug("Found digest", digest, "in process:", process)
        found = true
        break
      end
    end

    process_cursor = next_process_cursor
  until found == true or process_cursor == "0"

  return found
end
