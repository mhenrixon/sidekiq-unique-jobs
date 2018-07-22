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
  class ScriptError < StandardError
    # @param [Symbol] file_name the name of the lua script
    # @param [Redis::CommandError] source_exception exception to handle
    def initialize(file_name:, source_exception:)
      super("Problem compiling #{file_name}. Message: #{source_exception.message}")
    end
  end

  # Error raised from {OptionsWithFallback#lock_class}
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class UnknownLock < StandardError
  end
end
