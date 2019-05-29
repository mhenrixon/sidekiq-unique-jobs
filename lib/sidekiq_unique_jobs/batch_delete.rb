# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class BatchDelete provides batch deletion of digests
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  class BatchDelete
    CHUNK_SIZE = 100

    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Logging

    #
    # @!attribute [r] digests
    #   @return [Array<String>] a collection of digests to be deleted
    attr_reader :digests
    #
    # @!attribute [r] conn
    #   @return [Redis, RedisConnection, ConnectionPool] a redis connection/client
    attr_reader :conn

    #
    # Executes a batch deletion of the provided digests
    #
    # @param [Array<String>] digests the digests to delete
    # @param [Redis] conn the connection to use for deletion
    #
    # @return [void]
    #
    def self.call(digests, conn = nil)
      new(digests, conn).call
    end

    #
    # Initialize a new batch delete instance
    #
    # @param [Array<String>] digests the digests to delete
    # @param [Redis] conn the connection to use for deletion
    #
    def initialize(digests, conn = nil)
      @digests = digests
      @digests ||= []
      @digests.compact!
      @conn = conn
    end

    #
    # Executes a batch deletion of the provided digests
    # @note Just wraps batch_delete to be able to provide no connection
    #
    #
    def call
      return log_info("Nothing to delete; exiting.") if digests.none?

      log_info("Deleting batch with #{digests.size} digests")
      return batch_delete(conn) if conn

      redis { |conn| batch_delete(conn) }
    end

    #
    # Does the actual batch deletion
    #
    # @param [Redis] conn the connection to use for deletion
    #
    # @return [Integer] the number of deleted digests
    #
    def batch_delete(conn) # rubocop:disable Metrics/MethodLength
      count = 0
      digests.each_slice(CHUNK_SIZE) do |chunk|
        conn.pipelined do
          chunk.each do |digest|
            conn.del(digest)
            conn.zrem(SidekiqUniqueJobs::DIGESTS, digest)
            conn.del("#{digest}:QUEUED")
            conn.del("#{digest}:PRIMED")
            conn.del("#{digest}:LOCKED")
            conn.del("#{digest}:RUN")
            conn.del("#{digest}:RUN:QUEUED")
            conn.del("#{digest}:RUN:PRIMED")
            conn.del("#{digest}:RUN:LOCKED")
            count += 1
          end
        end
      end

      count
    end
  end
end
