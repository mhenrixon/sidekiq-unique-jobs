# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to replace the job on conflict
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Replace < OnConflict::Strategy
      #
      # @!attribute [r] queue
      #   @return [String] rthe sidekiq queue this job belongs to
      attr_reader :queue
      #
      # @!attribute [r] unique_digest
      #   @return [String] the unique digest to use for locking
      attr_reader :unique_digest

      # @param [Hash] item sidekiq job hash
      #
      # <description>
      #
      # @param [<type>] item <description>
      #
      def initialize(item, redis_pool = nil)
        super(item, redis_pool)
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
        keys = ["#{QUEUE_KEY}:#{queue}", SCHEDULE_SET, RETRY_SET]
        argv = [unique_digest]
        call_script(:delete_job_by_digest, keys, argv)
      end

      # Delete the keys belonging to the job
      def delete_lock
        call_script(:delete_by_digest, [unique_digest, DIGESTS_ZSET])
      end
    end
  end
end
