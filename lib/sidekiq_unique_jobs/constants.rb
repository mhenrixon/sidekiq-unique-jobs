module SidekiqUniqueJobs
  ARGS_KEY ||= 'args'.freeze
  AT_KEY ||= 'at'.freeze
  CLASS_KEY ||= 'class'.freeze
  JID_KEY ||= 'jid'.freeze
  LOG_DUPLICATE_KEY ||= 'log_duplicate_payload'.freeze
  QUEUE_KEY ||= 'queue'.freeze
  TESTING_CONSTANT ||= 'Testing'.freeze
  UNIQUE_KEY ||= 'unique'.freeze
  UNIQUE_LOCK_KEY ||= 'unique_lock'.freeze
  UNIQUE_ARGS_KEY ||= 'unique_args'.freeze
  UNIQUE_PREFIX_KEY ||= 'unique_prefix'.freeze
  UNIQUE_DIGEST_KEY ||= 'unique_digest'.freeze
  UNIQUE_ON_ALL_QUEUES_KEY ||= 'unique_on_all_queues'.freeze
  UNIQUE_TIMEOUT_KEY ||= 'unique_expiration'.freeze
  UNIQUE_ARGS_ENABLED_KEY ||= 'unique_args_enabled'.freeze
end
