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
    # @!attribute [r] wait
    #   @return [String] digest with `:WAIT` suffix
    attr_reader :wait
    #
    # @!attribute [r] work
    #   @return [String] digest with `:PROCESS` suffix
    attr_reader :work
    #
    #
    # @!attribute [r] version
    #   @return [String] digest with `:VERSION` suffix
    attr_reader :version

    #
    # Initialize a new Key
    #
    # @param [String] digest the digest to use as key
    #
    def initialize(digest)
      @digest  = digest
    end

    def unique_set
      SidekiqUniqueJobs::UNIQUE_SET
    end

    def waiting_set
      SidekiqUniqueJobs::WAITING_SET
    end

    def working_set
      SidekiqUniqueJobs::WORKING_SET
    end

    #
    # Returns all keys as an ordered array
    #
    #
    # @return [Array] an ordered array with all keys
    #
    def to_a
      [digest, wait, work, unique_set]
    end

    private

    def suffixed_key(variable)
      "#{digest}:#{variable}"
    end
  end
end
