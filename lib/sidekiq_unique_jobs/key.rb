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
    # @!attribute [r] available
    #   @return [String] digest with `:EXISTS` suffix
    attr_reader :exists
    #
    # @!attribute [r] available
    #   @return [String] digest with `:GRABBED` suffix
    attr_reader :grabbed
    #
    # @!attribute [r] available
    #   @return [String] digest with `:VERSION` suffix
    attr_reader :version

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
    end

    def all
      [available, exists, grabbed]
    end

    private

    def namespaced_key(variable)
      "#{digest}:#{variable}"
    end
  end
end
