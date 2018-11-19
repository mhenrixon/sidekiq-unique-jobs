# frozen_string_literal: true

class VersionCheck
  PATTERN = /(?<operator1>[<>=]+)?\s?(?<version1>(\d+.?)+)(\s+&&\s+)?(?<operator2>[<>=]+)?\s?(?<version2>(\d+.?)+)?/m.freeze # rubocop:disable LineLength
  def initialize(version, constraint)
    @version = Gem::Version.new(version)
    PATTERN.match(constraint.to_s) do |match|
      @version1  = Gem::Version.new(match[:version1])
      @operator1 = match[:operator1]
      if (version2 = match[:version2])
        @version2  = Gem::Version.new(version2)
      end
      @operator2 = match[:operator2]
    end

    fail ArgumentError, 'A version (5.0) is required to compare against' unless @version
    fail ArgumentError, 'At least one operator and version is required (<>= 5.1)' unless @operator1
  end

  def invalid?
    yield @operator1, @version1, @operator2, @version2 unless versions_satisfied?
  end

  def versions_satisfied?
    version1_satisfied? && version2_satisfied?
  end

  def version1_satisfied?
    @version.send(@operator1, @version1)
  end

  def version2_satisfied?
    return true if @operator2.nil? || @version2.nil?

    @version.send(@operator2.to_sym, @version2)
  end
end
