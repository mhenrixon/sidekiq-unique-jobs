# frozen_string_literal: true

module SidekiqUniqueJobs
  # Thin wrapper around Gem::Requirement for version constraint checking
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class VersionCheck
    # Check if a version satisfies a constraint
    #
    # @example
    #   VersionCheck.satisfied?("5.0.0", ">= 4.0.0") #=> true
    #   VersionCheck.satisfied?("3.0.0", ">= 4.0.0") #=> false
    #
    # @param [String] version the version to check
    # @param [String] constraint one or more version constraints (space or && separated)
    #
    # @return [true, false]
    def self.satisfied?(version, constraint)
      # Split on && or space-separated operator+version pairs
      parts = constraint.to_s.strip.scan(/[<>=!~]+\s*[\d.]+/)
      parts = [constraint.to_s] if parts.empty?
      Gem::Requirement.new(*parts.map(&:strip)).satisfied_by?(Gem::Version.new(version))
    end

    # Inverse of satisfied?
    #
    # @return [true, false]
    def self.unfulfilled?(version, constraint)
      !satisfied?(version, constraint)
    end
  end
end
