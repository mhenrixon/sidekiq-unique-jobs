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
    # @!attribute [r] available
    #   @return [String] digest with `:AVAILABLE` suffix
    attr_reader :available
    #
    # @!attribute [r] exists
    #   @return [String] digest with `:EXISTS` suffix
    attr_reader :exists
    #
    # @!attribute [r] grabbed
    #   @return [String] digest with `:GRABBED` suffix
    attr_reader :grabbed
    #
    # @!attribute [r] version
    #   @return [String] digest with `:VERSION` suffix
    attr_reader :version
    #
    # @!attribute [r] wait
    #   @return [String] digest with `:WAIT` suffix
    attr_reader :wait
    #
    # @!attribute [r] work
    #   @return [String] digest with `:PROCESS` suffix
    attr_reader :work

    #
    # Initialize a new Key
    #
    # @param [String] digest the digest to use as key
    #
    def initialize(digest)
      @digest    = digest
      @available = namespaced_key("AVAILABLE")
      @exists    = namespaced_key("EXISTS")
      @grabbed   = namespaced_key("GRABBED")
      @version   = namespaced_key("VERSION")
      @wait      = namespaced_key("WAIT")
      @work      = namespaced_key("WORK")
    end

    def unique_set
      SidekiqUniqueJobs::UNIQUE_SET
    end

    #
    # Returns all keys as an ordered array
    #
    #
    # @return [Array] an ordered array with all keys
    #
    def to_a
      [digest, wait, work, exists, grabbed, available, version, unique_set]
    end

    private

    def namespaced_key(variable)
      "#{digest}:#{variable}"
    end
  end
end
