class VersionCheck
  PATTERN = /(?<operator1>[<>=]+)?\s?(?<version1>(\d+.?)+)(\s+&&\s+)?(?<operator2>[<>=]+)?\s?(?<version2>(\d+.?)+)?/m
  def initialize(version, constraint)
    @version    = Gem::Version.new(version)
    PATTERN.match(constraint.to_s) do |match|
      @version_1  = Gem::Version.new(match[:version1])
      @operator_1 = match[:operator1]
      @version_2  = Gem::Version.new(match[:version2])
      @operator_2 = match[:operator2]
    end

    fail ArgumentError, "A version (5.0) is required to compare against" unless @version
    fail ArgumentError, "At least one operator and version is required (<>= 5.1)" unless @operator_1
  end

  def invalid?
    yield @operator_1, @version_1, @operator_2, @version_2 unless versions_satisfied?
  end

  def versions_satisfied?
    version_1_satisfied? && version_2_satisfied?
  end

  def version_1_satisfied?
    @version.send(@operator_1, @version_1)
  end

  def version_2_satisfied?
    return true if @operator_2.nil? || @version_2.nil?
    @version.send(@operator_2.to_sym, @version_2)
  end
end
