# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Gathers all configuration for a lock
  #   which helps reduce the amount of instance variables
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  class LockConfig
    #
    # @!attribute [r] lock
    #   @return [Symbol] the type of lock
    attr_reader :type
    #
    # @!attribute [r] limit
    #   @return [Integer] the number of simultaneous locks
    attr_reader :limit
    #
    # @!attribute [r] timeout
    #   @return [Integer, nil] the time to wait for a lock
    attr_reader :timeout
    #
    # @!attribute [r] ttl
    #   @return [Integer, nil] the time (in seconds) to live after successful
    attr_reader :ttl
    #
    # @!attribute [r] ttl
    #   @return [Integer, nil] the time (in milliseconds) to live after successful
    attr_reader :pttl
    #
    # @!attribute [r] lock_info
    #   @return [Boolean] indicate wether to use lock_info or not
    attr_reader :lock_info
    #
    # @!attribute [r] on_conflict
    #   @return [Symbol, Hash<Symbol, Symbol>] the strategies to use as conflict resolution
    attr_reader :on_conflict
    #
    # @!attribute [r] errors
    #   @return [Array<Hash<Symbol, Array<String>] a collection of configuration errors
    attr_reader :errors

    def self.from_worker(options)
      new(options.stringify_keys)
    end

    def initialize(job_hash = {})
      @type        = job_hash[LOCK]&.to_sym
      @limit       = job_hash.fetch(LOCK_LIMIT) { 1 }
      @timeout     = job_hash.fetch(LOCK_TIMEOUT) { 0 }
      @ttl         = job_hash.fetch(LOCK_TTL) { job_hash.fetch(LOCK_EXPIRATION) }.to_i
      @pttl        = ttl * 1_000
      @lock_info   = job_hash.fetch(LOCK_INFO) { SidekiqUniqueJobs.config.lock_info }
      @on_conflict = job_hash[ON_CONFLICT]
      @errors      = job_hash[ERRORS]
    end

    def wait_for_lock?
      timeout.nil? || timeout.positive?
    end
  end
end
