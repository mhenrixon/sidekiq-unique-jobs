# frozen_string_literal: true

#
# Module with constants to avoid string duplication
#
# @author Mikael Henriksson <mikael@zoolutions.se>
#
module SidekiqUniqueJobs
  ARGS                  ||= "args"
  AT                    ||= "at"
  CHANGELOGS            ||= "unique:changelog"
  CLASS                 ||= "class"
  DIGESTS               ||= "unique:digests"
  JID                   ||= "jid"
  LOCK_EXPIRATION       ||= "lock_expiration"
  LOCK                  ||= "lock"
  LOCK_LIMIT            ||= "lock_limit"
  LOCK_PREFIX           ||= "lock_prefix"
  LOCK_TIMEOUT          ||= "lock_timeout"
  LOCK_TTL              ||= "lock_ttl"
  LOG_DUPLICATE         ||= "log_duplicate"
  ON_CONFLICT           ||= "on_conflict"
  QUEUE                 ||= "queue"
  RETRY                 ||= "retry"
  SCHEDULE              ||= "schedule"
  UNIQUE_ACROSS_QUEUES  ||= "unique_across_queues"
  UNIQUE_ACROSS_WORKERS ||= "unique_across_workers"
  UNIQUE_ARGS           ||= "unique_args"
  UNIQUE_DIGEST         ||= "unique_digest"
  UNIQUE                ||= "unique"
  UNIQUE_PREFIX         ||= "unique_prefix"
end
