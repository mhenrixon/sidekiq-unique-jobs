# frozen_string_literal: true

module SidekiqUniqueJobs
  class BatchDelete
    CHUNK_SIZE = 100

    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Logging

    attr_reader :digests, :conn

    def self.call(digests, conn = nil)
      new(digests, conn).call
    end

    def initialize(digests = [], conn = nil)
      @digests = (digests || []).compact
      @conn    = conn
    end

    def call
      return log_debug("Nothing to delete; exiting.") if digests.none?

      log_debug("Deleting batch with #{digests.size} digests")
      return batch_delete(conn) if conn

      redis { |conn| batch_delete(conn) }
    end

    def batch_delete(conn)
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
          end
        end
      end
    end
  end
end
