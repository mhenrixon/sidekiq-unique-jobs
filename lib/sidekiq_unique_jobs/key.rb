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
    # @!attribute [r] prepared
    #   @return [String] the key for the list with prepared locks
    attr_reader :prepared
    #
    # @!attribute [r] obtained
    #   @return [String] the key for the list with obtained locks
    attr_reader :obtained
    #
    # @!attribute [r] locked
    #   @return [String] the key for the hash with locks
    attr_reader :locked
    #
    # @!attribute [r] changelog
    #   @return [String] the key for the changelog sorted set
    attr_reader :changelog

    #
    # Initialize a new Key
    #
    # @param [String] digest the digest to use as key
    #
    def initialize(digest)
      @digest    = digest
      @prepared  = suffixed_key("PREPARED")
      @obtained  = suffixed_key("OBTAINED")
      @locked    = suffixed_key("LOCKED")
      @changelog = "unique:changelog"
    end

    #
    # Returns all keys as an ordered array
    #
    # @return [Array] an ordered array with all keys
    #
    def to_a
      [digest, prepared, obtained, locked, changelog]
    end

    private

    def suffixed_key(variable)
      "#{digest}:#{variable}"
    end
  end
end
