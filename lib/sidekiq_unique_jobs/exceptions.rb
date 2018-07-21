# frozen_string_literal: true

module SidekiqUniqueJobs
  # Error raised when a Lua script fails to execute
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class Conflict < StandardError
    def initialize(item)
      super("Item with the key: #{item[UNIQUE_DIGEST_KEY]} is already scheduled or processing")
    end
  end

  # Error raised from {OnConflict::Raise}
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class Conflict < StandardError
    # @param [Hash] item the Sidekiq job hash
    # @option item [String] :unique_digest the unique digest (See: {UniqueArgs#unique_digest})
    def initialize(item)
      super("Item with the key: #{item[UNIQUE_DIGEST_KEY]} is already scheduled or processing")
    end
  end

  # Error raised from {OptionsWithFallback#lock_class}
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class UnknownLock < StandardError
  end
end
