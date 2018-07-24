# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to raise an error on conflict
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
      # @raise [SidekiqUniqueJobs::Conflict]
      def call(&block)
        return unless delete_job_by_digest
        block&.call
      end

      def delete_job_by_digest
        Scripts.call(
          :delete_job_by_digest, nil,
          keys: [queue, unique_digest],
          argv: []
        )
      end
    end
  end
end
