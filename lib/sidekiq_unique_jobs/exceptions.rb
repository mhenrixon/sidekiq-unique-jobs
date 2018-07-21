# frozen_string_literal: true

module SidekiqUniqueJobs
  class Conflict < StandardError
    def initialize(item)
      super("Item with the key: #{item[UNIQUE_DIGEST_KEY]} is already scheduled or processing")
    end
  end

  class ScriptError < StandardError
    def initialize(file_name:, source_exception:)
      super("Problem compiling #{file_name}. Message: #{source_exception.message}")
    end
  end

  class UnknownLock < StandardError
  end
end
