# frozen_string_literal: true

module SidekiqUniqueJobs
  # Key class wraps logic dealing with various lock keys
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class Key
    #
    # @!attribute [r] digest
    #   @return [String] the digest for which keys are created
    attr_reader :digest
    #
    # @!attribute [r] queued
    #   @return [String] the list with queued job_id's
    attr_reader :queued
    #
    # @!attribute [r] primed
    #   @return [String] the list with primed job_id's
    attr_reader :primed
    #
    # @!attribute [r] locked
    #   @return [String] the hash with locked job_id's
    attr_reader :locked
    #
    # @!attribute [r] changelog
    #   @return [String] the zset with changelog entries
    attr_reader :changelog
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
      @digest    = digest
      @queued    = suffixed_key("QUEUED")
      @primed    = suffixed_key("PRIMED")
      @locked    = suffixed_key("LOCKED")
      @changelog = SidekiqUniqueJobs::CHANGELOGS
      @digests   = SidekiqUniqueJobs::DIGESTS
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
    # Returns all keys as an ordered array
    #
    # @return [Array] an ordered array with all keys
    #
    def to_a
      [digest, queued, primed, locked, changelog, digests]
    end

    private

    def suffixed_key(variable)
      "#{digest}:#{variable}"
    end
  end
end
