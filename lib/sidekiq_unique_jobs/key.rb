# frozen_string_literal: true

module SidekiqUniqueJobs
  # Key class wraps logic dealing with various lock keys
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class Key
    #
    # @!attribute [r] digest
    #   @return [String] the digest for which keys are created
    attr_reader :lock_key

    #
    # Initialize a new Key
    #
    # @param [String] digest the digest to use as key
    #
    def initialize(digest)
      @lock_key = digest
    end

    def free_list
      @free_list ||= suffixed_key("FREE_LIST")
    end

    def held_list
      @held_list ||= suffixed_key("HELD_LIST")
    end

    def free_zet
      @free_zet ||= suffixed_key("FREE_ZET")
    end

    def held_zet
      @held_zet ||= suffixed_key("HELD_ZET")
    end

    def lock_hash
      @lock_hash ||= suffixed_key("LOCK")
    end

    #
    # Returns all keys as an ordered array
    #
    # @return [Array] an ordered array with all keys
    #
    def to_a
      [lock_key, free_list, held_list, free_zet, held_zet, lock_hash]
    end

    private

    def suffixed_key(variable)
      "#{lock_key}:#{variable}"
    end
  end
end
