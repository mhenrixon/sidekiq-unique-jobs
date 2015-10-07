module SidekiqUniqueJobs
  UNIQUE_KEY ||= 'unique'.freeze
  UNIQUE_LOCK_KEY ||= 'unique_lock'.freeze
  LOG_DUPLICATE_KEY ||= 'log_duplicate_payload'.freeze
  TESTING_CONSTANT ||= 'Testing'.freeze
end
