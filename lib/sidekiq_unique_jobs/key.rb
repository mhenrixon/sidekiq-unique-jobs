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

    # v8 compatibility — these attributes are deprecated in v9
    # @deprecated Use {#locked} instead
    attr_reader :queued, :primed, :info, :changelog, :expiring_digests

    #
    # Initialize a new Key
    #
    # @param [String] digest the digest to use as key
    #
    def initialize(digest)
      @digest           = digest
      @locked           = suffixed_key("LOCKED")
      @digests          = DIGESTS

      # v8 compatibility — kept for migration and old Lua scripts
      @queued           = suffixed_key("QUEUED")
      @primed           = suffixed_key("PRIMED")
      @info             = suffixed_key("INFO")
      @changelog        = CHANGELOGS
      @expiring_digests = EXPIRING_DIGESTS
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

    #
    # Provides the only important information about this keys
    #
    #
    # @return [String]
    #
    def to_s
      digest
    end

    # @see to_s
    def inspect
      digest
    end

    #
    # Compares keys by digest
    #
    # @param [Key] other the key to compare with
    #
    # @return [true, false]
    #
    def ==(other)
      digest == other.digest
    end

    #
    # Returns v9 keys as an ordered array (locked, digests)
    #
    # @return [Array] an ordered array with v9 keys
    #
    def to_a_v9
      [locked, digests]
    end

    #
    # Returns all keys as an ordered array (v8 compatibility)
    #
    # @return [Array] an ordered array with all keys
    #
    def to_a
      [digest, queued, primed, locked, info, changelog, digests, expiring_digests]
    end

    private

    def suffixed_key(variable)
      "#{digest}:#{variable}"
    end
  end
end
