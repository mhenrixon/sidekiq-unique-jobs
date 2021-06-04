# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class Deprecation provides logging of deprecations
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class Deprecation
    def self.muted
      orig_val = Thread.current[:uniquejobs_mute_deprecations]
      Thread.current[:uniquejobs_mute_deprecations] = true
      yield
    ensure
      Thread.current[:uniquejobs_mute_deprecations] = orig_val
    end

    def self.muted?
      Thread.current[:uniquejobs_mute_deprecations] == true
    end

    def self.warn(msg)
      return if SidekiqUniqueJobs::Deprecation.muted?

      warn "DEPRECATION WARNING: #{msg}"
    end

    def self.warn_with_backtrace(msg)
      return if SidekiqUniqueJobs::Deprecation.muted?

      trace = "\n\nCALLED FROM:\n#{caller.join("\n")}"
      warn(msg + trace)
    end
  end
end
