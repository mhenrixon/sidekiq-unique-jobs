# frozen_string_literal: true

module SidekiqUniqueJobs
  module Timeout
    # Calculates timeout and expiration
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Calculator
      include SidekiqUniqueJobs::SidekiqWorkerMethods

      # @attr [Hash] item the Sidekiq job hash
      attr_reader :item

      # @param [Hash] item the Sidekiq job hash
      # @option item [Integer, nil] :lock_ttl the configured lock expiration
      # @option item [Integer, nil] :lock_timeout the configured lock timeout
      # @option item [String] :class the class of the sidekiq worker
      # @option item [Float] :at the unix time the job is scheduled at
      def initialize(item)
        @item         = item
        @worker_class = item[CLASS]
      end

      # The time until a job is scheduled
      # @return [Integer] the number of seconds until job is scheduled
      def time_until_scheduled
        return 0 unless scheduled_at

        scheduled_at.to_i - Time.now.utc.to_i
      end

      # The time a job is scheduled
      # @return [Float] the exact unix time the job is scheduled at
      def scheduled_at
        @scheduled_at ||= item[AT]
      end

      # The configured lock_ttl
      def lock_ttl
        @lock_ttl ||= begin
          ttl = item[LOCK_TTL]
          ttl ||= worker_options[LOCK_TTL]
          ttl ||= item[LOCK_EXPIRATION] # TODO: Deprecate at some point
          ttl ||= worker_options[LOCK_EXPIRATION] # TODO: Deprecate at some point
          ttl ||= default_lock_ttl
          ttl && ttl.to_i + time_until_scheduled
        end
      end

      # The configured lock_timeout
      def lock_timeout
        @lock_timeout = begin
          timeout = default_worker_options[LOCK_TIMEOUT]
          timeout = default_lock_timeout if default_lock_timeout
          timeout = worker_options[LOCK_TIMEOUT] if worker_options.key?(LOCK_TIMEOUT)
          timeout
        end
      end

      # The default lock_timeout of this gem
      def default_lock_timeout
        SidekiqUniqueJobs.config.default_lock_timeout
      end

      def default_lock_ttl
        SidekiqUniqueJobs.config.default_lock_ttl
      end
    end
  end
end
