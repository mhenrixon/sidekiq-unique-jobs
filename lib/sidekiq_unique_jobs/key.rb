# frozen_string_literal: true

module SidekiqUniqueJobs
  # Key class wraps logic dealing with various lock keys
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class Key
    #
    # @!attribute [r] digest
    #   @return [String] the digest key for which keys are created
    attr_reader :digest
    #
    # @!attribute [r] locked
    #   @return [String] the hash key with locked job_id's
    attr_reader :locked
    #
    # @!attribute [r] digests
    #   @return [String] the zset with locked digests
    attr_reader :digests

    #
    # Initialize a new Key
    #
    # @param [String] digest the digest to use as key
    #
    def initialize(digest)
      @digest  = digest
      @locked  = "#{digest}:LOCKED"
      @digests = DIGESTS
    end

    #
    # Returns the per-process working list key
    #
    # @param [String] identity the process identity (hostname:pid)
    #
    # @return [String] the working list key
    #
    def self.working(identity)
      "uniquejobs:working:#{identity}"
    end

    #
    # Returns the heartbeat key for a process
    #
    # @param [String] identity the process identity (hostname:pid)
    #
    # @return [String] the heartbeat key
    #
    def self.heartbeat(identity)
      "uniquejobs:heartbeat:#{identity}"
    end

    def to_s
      digest
    end

    def inspect
      digest
    end

    def ==(other)
      digest == other.digest
    end

    #
    # Returns keys for Lua scripts: [locked, digests]
    #
    # @return [Array<String>]
    #
    def to_a
      [locked, digests]
    end

    private

    def suffixed_key(variable)
      "#{digest}:#{variable}"
    end
  end
end
