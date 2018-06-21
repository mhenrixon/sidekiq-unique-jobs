# frozen_string_literal: true

module SidekiqUniqueJobs
  class LockTimeout < StandardError
  end

  class RunLockFailed < StandardError
  end

  class ScriptError < StandardError
    def initialize(file_name:, source_exception:)
      super("Problem compiling #{file_name}. Message: #{source_exception.message}")
    end
  end

  class UniqueKeyMissing < ArgumentError
  end

  class JidMissing < ArgumentError
  end

  class MaxLockTimeMissing < ArgumentError
  end

  class UnexpectedValue < StandardError
  end

  class UnknownLock < StandardError
  end
end
