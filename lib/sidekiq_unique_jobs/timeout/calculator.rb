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
      # @option item [Integer, nil] :lock_expiration the configured lock expiration
      # @option item [Integer, nil] :lock_timeout the configured lock timeout
      # @option item [String] :class the class of the sidekiq worker
      # @option item [Float] :at the unix time the job is scheduled at
      def initialize(item)
        @item         = item
        @worker_class = item[CLASS_KEY]
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
        @scheduled_at ||= item[AT_KEY]
      end

      # The configured lock_expiration
      def lock_expiration
        @lock_expiration ||= begin
          expiration = item[LOCK_EXPIRATION_KEY]
          expiration ||= worker_options[LOCK_EXPIRATION_KEY]
          expiration && expiration.to_i + time_until_scheduled
        end
      end

      # The configured lock_timeout
      def lock_timeout
        @lock_timeout = begin
          timeout = default_worker_options[LOCK_TIMEOUT_KEY]
          timeout = default_lock_timeout if default_lock_timeout
          timeout = worker_options[LOCK_TIMEOUT_KEY] if worker_options.key?(LOCK_TIMEOUT_KEY)
          timeout
        end
      end

      # The default lock_timeout of this gem
      def default_lock_timeout
        SidekiqUniqueJobs.config.default_lock_timeout
      end
    end
  end
end
