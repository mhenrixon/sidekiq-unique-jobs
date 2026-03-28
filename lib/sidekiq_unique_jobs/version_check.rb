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
      str = constraint.to_s.strip
      return Gem::Requirement.new(">= 0").satisfied_by?(Gem::Version.new(version)) if str.empty?

      parts = str.split("&&").flat_map { |s| s.split(",") }.map(&:strip).reject(&:empty?)
      parts = split_space_separated(str) if parts.size == 1
      Gem::Requirement.new(*parts).satisfied_by?(Gem::Version.new(version))
    end

    # Split ">= 3.2 <= 4.0" into [">= 3.2", "<= 4.0"] without regex
    def self.split_space_separated(str)
      result = []
      current = +""
      tokens = str.split(" ")
      tokens.each do |token|
        if current.empty? || "<>=!~".include?(token[0])
          result << current.strip unless current.empty?
          current = token
        else
          current = "#{current} #{token}"
        end
      end
      result << current.strip unless current.empty?
      result
    end
    private_class_method :split_space_separated

    # Inverse of satisfied?
    #
    # @return [true, false]
    def self.unfulfilled?(version, constraint)
      !satisfied?(version, constraint)
    end
  end
end
