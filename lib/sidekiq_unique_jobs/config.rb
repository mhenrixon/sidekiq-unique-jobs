# frozen_string_literal: true

module SidekiqUniqueJobs
  # Shared class for dealing with gem configuration
  #
  # @author Mauro Berlanda <mauro.berlanda@gmail.com>
  class Config < Concurrent::MutableStruct.new(
    :default_lock_timeout,
    :default_lock_ttl,
    :enabled,
    :unique_prefix,
    :logger,
    :locks,
    :strategies,
    :debug_lua,
    :max_history,
    :max_orphans,
  )

    LOCKS_WHILE_ENQUEUED = {
      until_executing: SidekiqUniqueJobs::Lock::UntilExecuting,
      until_before_perform: SidekiqUniqueJobs::Lock::UntilExecuting,
      while_enqueued: SidekiqUniqueJobs::Lock::UntilExecuting,
    }.freeze

    LOCKS_FROM_PUSH_TO_PROCESSED = {
      until_executed: SidekiqUniqueJobs::Lock::UntilExecuted,
      until_after_perform: SidekiqUniqueJobs::Lock::UntilExecuted,
      until_completed: SidekiqUniqueJobs::Lock::UntilExecuted,
      until_successfully_completed: SidekiqUniqueJobs::Lock::UntilExecuted,
      until_processed: SidekiqUniqueJobs::Lock::UntilExecuted,
      until_performed: SidekiqUniqueJobs::Lock::UntilExecuted,
      until_and_while_executing: SidekiqUniqueJobs::Lock::UntilAndWhileExecuting,
    }.freeze

    LOCKS_WITHOUT_UNLOCK = {
      until_expired: SidekiqUniqueJobs::Lock::UntilExpired,
      until_timeout: SidekiqUniqueJobs::Lock::UntilExpired,
      without_unlock: SidekiqUniqueJobs::Lock::UntilExpired,
    }.freeze

    LOCKS_WHEN_BUSY = {
      while_executing: SidekiqUniqueJobs::Lock::WhileExecuting,
      while_busy: SidekiqUniqueJobs::Lock::WhileExecuting,
      while_working: SidekiqUniqueJobs::Lock::WhileExecuting,
      around_perform: SidekiqUniqueJobs::Lock::WhileExecuting,
      while_executing_reject: SidekiqUniqueJobs::Lock::WhileExecutingReject,
    }.freeze

    DEFAULT_LOCKS =
      LOCKS_WHEN_BUSY.dup
                     .merge(LOCKS_WHILE_ENQUEUED.dup)
                     .merge(LOCKS_WITHOUT_UNLOCK.dup)
                     .merge(LOCKS_FROM_PUSH_TO_PROCESSED.dup)
                     .freeze

    DEFAULT_STRATEGIES = {
      log: SidekiqUniqueJobs::OnConflict::Log,
      raise: SidekiqUniqueJobs::OnConflict::Raise,
      reject: SidekiqUniqueJobs::OnConflict::Reject,
      replace: SidekiqUniqueJobs::OnConflict::Replace,
      reschedule: SidekiqUniqueJobs::OnConflict::Reschedule,
    }.freeze

    DEFAULT_PREFIX       = "uniquejobs"
    DEFAULT_LOCK_TIMEOUT = 0
    DEFAULT_LOCK_TTL     = nil
    DEFAULT_ENABLED      = true
    DEFAULT_DEBUG_LUA    = false
    DEFAULT_MAX_HISTORY  = 1_000
    DEFAULT_MAX_ORPHANS  = 1_000

    #
    # Returns a default configuration
    #
    #
    # @return [Concurrent::MutableStruct] a representation of the configuration object
    #
    def self.default
      new(
        DEFAULT_LOCK_TIMEOUT,
        DEFAULT_LOCK_TTL,
        DEFAULT_ENABLED,
        DEFAULT_PREFIX,
        Sidekiq.logger,
        DEFAULT_LOCKS,
        DEFAULT_STRATEGIES,
        DEFAULT_DEBUG_LUA,
        DEFAULT_MAX_HISTORY,
        DEFAULT_MAX_ORPHANS,
      )
    end

    #
    # Adds a lock type to the configuration. It will raise if the lock exists already
    #
    # @param [String] name the name of the lock
    # @param [Class] klass the class describing the lock
    #
    # @return [void]
    #
    def add_lock(name, klass)
      lock_sym = name.to_sym
      raise DuplicateLock, ":#{name} already defined, please use another name" if locks.key?(lock_sym)

      new_locks = locks.dup.merge(lock_sym => klass).freeze
      self.locks = new_locks
    end

    #
    # Adds an on_conflict strategy to the configuration.
    #   It will raise if the strategy exists already
    #
    # @param [String] name the name of the custom strategy
    # @param [Class] klass the class describing the strategy
    #
    def add_strategy(name, klass)
      strategy_sym = name.to_sym
      raise DuplicateStrategy, ":#{name} already defined, please use another name" if strategies.key?(strategy_sym)

      new_strategies = strategies.dup.merge(strategy_sym => klass).freeze
      self.strategies = new_strategies
    end
  end
end
