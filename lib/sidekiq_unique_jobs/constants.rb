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
  DIGESTS               ||= "uniquejobs:digests"
  JID                   ||= "jid"
  LIVE_VERSION          ||= "uniquejobs:live"
  DEAD_VERSION          ||= "uniquejobs:dead"
  LIMIT                 ||= "limit"
  LOCK                  ||= "lock"
  LOCK_EXPIRATION       ||= "lock_expiration"
  LOCK_LIMIT            ||= "lock_limit"
  LOCK_PREFIX           ||= "lock_prefix"
  LOCK_TIMEOUT          ||= "lock_timeout"
  LOCK_TTL              ||= "lock_ttl"
  LOCK_TYPE             ||= "lock_type"
  LOG_DUPLICATE         ||= "log_duplicate"
  ON_CONFLICT           ||= "on_conflict"
  QUEUE                 ||= "queue"
  RETRY                 ||= "retry"
  SCHEDULE              ||= "schedule"
  TIMEOUT               ||= "timeout"
  TTL                   ||= "ttl"
  TYPE                  ||= "type"
  UNIQUE                ||= "unique"
  UNIQUE_ACROSS_QUEUES  ||= "unique_across_queues"
  UNIQUE_ACROSS_WORKERS ||= "unique_across_workers"
  UNIQUE_ARGS           ||= "unique_args"
  UNIQUE_DIGEST         ||= "unique_digest"
  UNIQUE_PREFIX         ||= "unique_prefix"
  WORKER                ||= "worker"
end
