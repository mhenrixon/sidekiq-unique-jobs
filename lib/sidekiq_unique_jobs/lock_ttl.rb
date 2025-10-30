# frozen_string_literal: true

module SidekiqUniqueJobs
  # Calculates timeout and expiration
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class LockTTL
    # includes "SidekiqUniqueJobs::SidekiqWorkerMethods"
    # @!parse include SidekiqUniqueJobs::SidekiqWorkerMethods
    include SidekiqUniqueJobs::SidekiqWorkerMethods

    #
    # Computes lock ttl from job arguments, sidekiq_options.
    #   Falls back to {SidekiqUniqueJobs::Config#lock_ttl}
    #
    # @note this method takes into consideration the time
    #   until a job is scheduled
    #
    #
    # @return [Integer] the number of seconds to live
    #
    def self.calculate(item)
      new(item).calculate
    end

    # @!attribute [r] item
    #   @return [Hash] the Sidekiq job hash
    attr_reader :item

    # @param [Hash] item the Sidekiq job hash
    # @option item [Integer, nil] :lock_ttl the configured lock expiration
    # @option item [Integer, nil] :lock_timeout the configured lock timeout
    # @option item [String] :class the class of the sidekiq worker
    # @option item [Float] :at the unix time the job is scheduled at
    def initialize(item)
      @item = item
      self.job_class = item[CLASS]
    end

    #
    # Calculates the time until the job is scheduled starting from now
    #
    #
    # @return [Integer] the number of seconds until job is scheduled
    #
    def time_until_scheduled
      return 0 unless scheduled_at

      scheduled_at.to_i - Time.now.utc.to_i
    end

    # The time a job is scheduled
    # @return [Float] the exact unix time the job is scheduled at
    def scheduled_at
      @scheduled_at ||= item[AT]
    end

    #
    # Computes lock ttl from job arguments, sidekiq_options.
    #   Falls back to {SidekiqUniqueJobs::Config#lock_ttl}
    #
    # @note this method takes into consideration the time
    #   until a job is scheduled
    #
    #
    # @return [Integer] the number of seconds to live
    #
    def calculate
      ttl = fetch_ttl
      return unless ttl

      timing = calculate_timing(ttl)
      return unless timing

      timing.to_i + time_until_scheduled
    end

    private

    def fetch_ttl
      item[LOCK_TTL] ||
        job_options[LOCK_TTL] ||
        item[LOCK_EXPIRATION] || # TODO: Deprecate at some point
        job_options[LOCK_EXPIRATION] || # TODO: Deprecate at some point
        SidekiqUniqueJobs.config.lock_ttl
    end

    def calculate_timing(ttl)
      case ttl
      when String, Numeric, ActiveSupport::Duration
        ttl
      when Proc
        ttl.call(item[ARGS])
      when Symbol
        job_class.send(ttl, item[ARGS])
      else
        raise ArgumentError, "#{ttl.class} is not supported for lock_ttl"
      end
    end
  end
end
