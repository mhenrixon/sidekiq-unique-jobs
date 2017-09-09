# frozen_string_literal: true

module SidekiqUniqueJobs
  class LockTimeout < StandardError
  end

  class RunLockFailed < StandardError
  end

  class ScriptError < StandardError
  end

  class UniqueKeyMissing < ArgumentError
  end

  class JidMissing < ArgumentError
  end

  class MaxLockTimeMissing < ArgumentError
  end

  class UnexpectedValue < StandardError
  end
end
