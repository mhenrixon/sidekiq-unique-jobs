# frozen_string_literal: true

module SidekiqUniqueJobs
  # Shared class for dealing with gem configuration
  #
  # @author Mauro Berlanda <mauro.berlanda@gmail.com>
  class Config < Concurrent::MutableStruct.new(
    :default_lock_timeout,
    :enabled,
    :unique_prefix,
    :logger,
    :locks,
    :strategies,
  )
    DEFAULT_LOCKS = {
      until_and_while_executing: SidekiqUniqueJobs::Lock::UntilAndWhileExecuting,
      until_executed: SidekiqUniqueJobs::Lock::UntilExecuted,
      until_executing: SidekiqUniqueJobs::Lock::UntilExecuting,
      until_expired: SidekiqUniqueJobs::Lock::UntilExpired,
      until_timeout: SidekiqUniqueJobs::Lock::UntilExpired,
      while_executing: SidekiqUniqueJobs::Lock::WhileExecuting,
      while_executing_reject: SidekiqUniqueJobs::Lock::WhileExecutingReject,
    }.freeze

    DEFAULT_STRATEGIES = {
      log: SidekiqUniqueJobs::OnConflict::Log,
      raise: SidekiqUniqueJobs::OnConflict::Raise,
      reject: SidekiqUniqueJobs::OnConflict::Reject,
      replace: SidekiqUniqueJobs::OnConflict::Replace,
      reschedule: SidekiqUniqueJobs::OnConflict::Reschedule,
    }.freeze

    # Returns a default configuration
    # @return [Concurrent::MutableStruct] a representation of the configuration object
    def self.default
      new(
        0,
        true,
        "uniquejobs",
        Sidekiq.logger,
        DEFAULT_LOCKS,
        DEFAULT_STRATEGIES,
      )
    end

    # Adds a lock type to the configuration. It will raise if the lock exists already
    #
    # @param [String] name the name of the lock
    # @param [Class] klass the class describing the lock
    def add_lock(name, klass)
      raise ArgumentError, "Lock #{name} already defined, please use another name" if locks.key?(name.to_sym)

      new_locks = locks.dup.merge(name.to_sym => klass).freeze
      self.locks = new_locks
    end

    # Adds an on_conflict strategy to the configuration.
    # It will raise if the strategy exists already
    #
    # @param [String] name the name of the custom strategy
    # @param [Class] klass the class describing the strategy
    def add_strategy(name, klass)
      raise ArgumentError, "strategy #{name} already defined, please use another name" if strategies.key?(name.to_sym)

      new_strategies = strategies.dup.merge(name.to_sym => klass).freeze
      self.strategies = new_strategies
    end
  end
end
