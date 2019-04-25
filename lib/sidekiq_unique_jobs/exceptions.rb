# frozen_string_literal: true

module SidekiqUniqueJobs
  class UniqueJobsError < ::RuntimeError
  end

  # Error raised when a Lua script fails to execute
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class InvalidUniqueArguments < UniqueJobsError
    def initialize(given:, worker_class:, unique_args_method:)
      uniq_args_meth  = worker_class.method(unique_args_method)
      num_args        = uniq_args_meth.arity
      # source_location = uniq_args_meth.source_location

      super(
        "#{worker_class}#unique_args takes #{num_args} arguments, received #{given.inspect}"
      )
    end
  end

  # Error raised when a Lua script fails to execute
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class Conflict < UniqueJobsError
    def initialize(item)
      super("Item with the key: #{item[UNIQUE_DIGEST_KEY]} is already scheduled or processing")
    end
  end

  # Error raised from {OnConflict::Raise}
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class ScriptError < UniqueJobsError
    # @param [Symbol] file_name the name of the lua script
    # @param [Redis::CommandError] source_exception exception to handle
    def initialize(file_name:, source_exception:)
      super("Problem compiling #{file_name}. Message: #{source_exception.message}")
    end
  end

  # Error raised from {OptionsWithFallback#lock_class}
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class UnknownLock < UniqueJobsError
  end
end
