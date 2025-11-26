local function find_digest_in_process_set(digest, threshold)
  local process_cursor = 0
  local job_cursor     = 0
  local found          = false

  -- Cache digest transformation outside the loop - major performance win!
  local digest_without_run = string.gsub(digest, ':RUN', '')

  log_debug("Searching in process list",
            "for digest:", digest,
            "cursor:", process_cursor)

  repeat
    local process_paginator   = redis.call("SSCAN", "processes", process_cursor, "MATCH", "*")
    local next_process_cursor = process_paginator[1]
    local processes           = process_paginator[2]
    log_debug("Found number of processes:", #processes, "next cursor:", next_process_cursor)

    for _, process in ipairs(processes) do
      local workers_key = process .. ":work"
      log_debug("searching in process set:", process,
                "for digest:", digest,
                "cursor:", process_cursor)

      local jobs = redis.call("HGETALL", workers_key)

      if #jobs == 0 then
        log_debug("No entries in:", workers_key)
      else
        for i = 1, #jobs, 2 do
          local jobstr = jobs[i + 1]
          -- Use cached digest transformation - avoid repeated string.gsub on digest
          local jobstr_without_run = string.gsub(jobstr, ':RUN', '')

          if string.find(jobstr_without_run, digest_without_run) then
            log_debug("Found digest", digest, "in:", workers_key)
            found = true
            break
          end

          local job = cjson.decode(jobstr)
          if job.payload.created_at > threshold then
            found = true
            break
          end
        end
      end

      if found == true then
        break
      end
    end

    process_cursor = next_process_cursor
  until found == true or process_cursor == "0"

  return found
end
