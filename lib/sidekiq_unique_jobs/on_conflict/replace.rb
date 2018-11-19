# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to replace the job on conflict
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Replace < OnConflict::Strategy
      attr_reader :queue, :unique_digest

      # @param [Hash] item sidekiq job hash
      def initialize(item)
        super
        @queue         = item[QUEUE_KEY]
        @unique_digest = item[UNIQUE_DIGEST_KEY]
      end

      # Replace the old job in the queue
      # @yield to retry the lock after deleting the old one
      def call(&block)
        return unless delete_job_by_digest

        delete_lock
        block&.call
      end

      # Delete the job from either schedule, retry or the queue
      def delete_job_by_digest
        Scripts.call(
          :delete_job_by_digest,
          nil,
          keys: ["#{QUEUE_KEY}:#{queue}", SCHEDULE_SET, RETRY_SET], argv: [unique_digest],
        )
      end

      # Delete the keys belonging to the job
      def delete_lock
        Scripts.call(:delete_by_digest, nil, keys: [UNIQUE_SET, unique_digest])
      end
    end
  end
end
