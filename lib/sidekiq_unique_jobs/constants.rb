# frozen_string_literal: true

#
# Module with constants to avoid string duplication
#
# @author Mikael Henriksson <mikael@zoolutions.se>
#
module SidekiqUniqueJobs
  ARGS_KEY                  ||= "args"
  AT_KEY                    ||= "at"
  CLASS_KEY                 ||= "class"
  JID_KEY                   ||= "jid"
  LOCK_EXPIRATION_KEY       ||= "lock_expiration"
  LOCK_TIMEOUT_KEY          ||= "lock_timeout"
  LOG_DUPLICATE_KEY         ||= "log_duplicate_payload"
  QUEUE_KEY                 ||= "queue"
  UNIQUE_ACROSS_QUEUES_KEY  ||= "unique_across_queues"
  UNIQUE_ACROSS_WORKERS_KEY ||= "unique_across_workers"
  UNIQUE_ARGS_KEY           ||= "unique_args"
  UNIQUE_DIGEST_KEY         ||= "unique_digest"
  UNIQUE_KEY                ||= "unique"
  UNIQUE_SET                ||= "unique:keys"
  LOCK_KEY                  ||= "lock"
  ON_CONFLICT_KEY           ||= "on_conflict"
  UNIQUE_ON_ALL_QUEUES_KEY  ||= "unique_on_all_queues" # TODO: Remove in v6.1
  UNIQUE_PREFIX_KEY         ||= "unique_prefix"
  RETRY_SET                 ||= "retry"
  SCHEDULE_SET              ||= "schedule"
end
