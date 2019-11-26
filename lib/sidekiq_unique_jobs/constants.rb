# frozen_string_literal: true

#
# Module with constants to avoid string duplication
#
# @author Mikael Henriksson <mikael@zoolutions.se>
#
module SidekiqUniqueJobs
  ARGS                  ||= "args"
  AT                    ||= "at"
  CHANGELOGS            ||= "uniquejobs:changelog"
  CLASS                 ||= "class"
  DEAD_VERSION          ||= "uniquejobs:dead"
  DIGESTS               ||= "uniquejobs:digests"
  ERRORS                ||= "errors"
  JID                   ||= "jid"
  LIMIT                 ||= "limit"
  LIVE_VERSION          ||= "uniquejobs:live"
  LOCK                  ||= "lock"
  LOCK_EXPIRATION       ||= "lock_expiration"
  LOCK_INFO             ||= "lock_info"
  LOCK_LIMIT            ||= "lock_limit"
  LOCK_PREFIX           ||= "lock_prefix"
  LOCK_TIMEOUT          ||= "lock_timeout"
  LOCK_TTL              ||= "lock_ttl"
  LOCK_TYPE             ||= "lock_type"
  LOG_DUPLICATE         ||= "log_duplicate"
  ON_CLIENT_CONFLICT    ||= "on_client_conflict"
  ON_CONFLICT           ||= "on_conflict"
  ON_SERVER_CONFLICT    ||= "on_server_conflict"
  QUEUE                 ||= "queue"
  RETRY                 ||= "retry"
  SCHEDULE              ||= "schedule"
  TIME                  ||= "time"
  TIMEOUT               ||= "timeout"
  TTL                   ||= "ttl"
  TYPE                  ||= "type"
  UNIQUE                ||= "unique"
  UNIQUE_ACROSS_QUEUES  ||= "unique_across_queues"
  UNIQUE_ACROSS_WORKERS ||= "unique_across_workers"
  UNIQUE_ARGS           ||= "unique_args"
  UNIQUE_DIGEST         ||= "unique_digest"
  UNIQUE_PREFIX         ||= "unique_prefix"
  UNIQUE_REAPER         ||= "uniquejobs:reaper"
  WORKER                ||= "worker"
end
